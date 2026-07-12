# Design Choices

This document records *why* the driver is written the way it is. Every
non-obvious decision here was verified empirically on real hardware (a
Logi Bolt receiver, product id `0xc548`), not assumed. If you touch this
driver, read this first.

## Background: what this module actually does

Mainline already has basic Bolt receiver support (`recvr_type_bolt`, the
`0xc548` id). The purpose of *this* work is narrower: before these
changes the receiver's Logitech-specific HID++ features did not work —
the device was effectively handled as a generic HID device. Binding it
correctly to the logitech-dj driver enables those features, the most
important (and most tested) being **battery level reporting** for
connected peripherals.

## Decision 1: Bind non-DJ interfaces as generic HID, use only interface 2

The Bolt receiver exposes **three** USB interfaces:

| Interface | SubClass / Protocol      | Role              |
|-----------|--------------------------|-------------------|
| 0         | Boot / Keyboard          | boot keyboard     |
| 1         | Boot / Mouse             | boot mouse        |
| 2         | SubClass 0, Protocol 0   | HID++ / DJ control |

In `logi_dj_probe`, `recvr_type_bolt` sets `no_dj_interfaces = 3`. The
existing generic-routing check is `ifnum >= no_dj_interfaces`, i.e.
`ifnum >= 3` — which **never matches** on this receiver, because the
highest interface number is 2. Without an extra check, all three
interfaces would fall through to the DJ handling path.

A Bolt-specific check therefore forces every interface except
`LOGITECH_DJ_INTERFACE_NUMBER` (2) to be handled as a generic
per-application HID device:

```c
if (id->driver_data == recvr_type_bolt && intf &&
    ifnum != LOGITECH_DJ_INTERFACE_NUMBER) {
        hdev->quirks |= HID_QUIRK_INPUT_PER_APP;
        return hid_hw_start(hdev, HID_CONNECT_DEFAULT);
}
```

**Why this check is necessary (tested):** An attempt was made to run all
three interfaces through the DJ path. The mouse could eventually be made
to work, but the keyboard broke and did not function correctly. Leaving
interfaces 0 and 1 as generic HID and using only interface 2 for the
HID++ features is what makes both keyboard and mouse work reliably.

## Decision 2: Handle Bolt unpair inline (direct schedule + early return)

When a device is unpaired (e.g. via Solaar), the Bolt receiver emits an
explicit unpaired notification. Without handling it, the unpaired device
lingers — it stays in the battery list and is not removed, similar to how
stale disconnect state behaves.

The unpair is handled directly in `logi_dj_hidpp_event`:

```c
if (djrcv_dev->type == recvr_type_bolt &&
    hidpp_report->report_id == REPORT_ID_HIDPP_SHORT &&
    hidpp_report->sub_id == REPORT_TYPE_NOTIF_DEVICE_UNPAIRED) {
        struct dj_workitem workitem = {
                .device_index = device_index,
                .type = WORKITEM_TYPE_UNPAIRED,
        };

        kfifo_in(&djrcv_dev->notif_fifo, &workitem, sizeof(workitem));
        schedule_work(&djrcv_dev->work);
        spin_unlock_irqrestore(&djrcv_dev->lock, flags);
        return false;
}
```

**Why not fall through like the 27MHz path?** The 27MHz receiver code
queues its work item, sets `dj_dev = NULL`, and lets execution continue
to the shared dispatch at the bottom of the function. That was tested
here as an alternative for Bolt and rejected.

The shared dispatch is:

```c
if (dj_dev) {
        logi_dj_recv_forward_report(dj_dev, data, size);
} else {
        if (hidpp_report->sub_id == REPORT_TYPE_NOTIF_DEVICE_CONNECTED)
                logi_hidpp_recv_queue_notif(hdev, hidpp_report);
        else
                logi_dj_recv_queue_unknown_work(djrcv_dev);
}
```

The else-branch only special-cases `DEVICE_CONNECTED`. An unpair
notification is not CONNECTED, so after `dj_dev = NULL` the fall-through
lands in `logi_dj_recv_queue_unknown_work`, which queues a
`WORKITEM_TYPE_UNKNOWN` full re-enumeration.

**Observed behaviour of the fall-through variant (dmesg):** a single
unpair event produced *two* work items back-to-back (near-identical
timestamps):

```
... bolt unpair queued UNPAIRED, dev_index=2, falling through
... logi_dj_recv_queue_unknown_work called (UNKNOWN enumeration)
```

So the fall-through works (the device did disappear) but performs a
redundant full re-enumeration on every unpair. Handling the unpair
inline with `schedule_work()` + early return removes that redundant work.

## Notes / open items

- The commit subject "add support for the Logi Bolt receiver" is
  misleading, since mainline already has basic Bolt support. If this is
  ever submitted upstream, reword it to describe the real change
  (enabling HID++ battery reporting for an already-supported receiver).
- Before pursuing upstreaming, confirm whether current mainline already
  closes the battery-reporting gap this module addresses. If it does,
  there is nothing to send.
- The `schedule_work()` + `return false` semantics return `0` to
  hid-core, which keeps the report visible to the receiver's hidraw
  node. This matches the existing `return false` used elsewhere in the
  same function.
