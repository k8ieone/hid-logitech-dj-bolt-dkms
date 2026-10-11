# hid-logitech-dj-bolt-dkms

This directory contains an out-of-tree DKMS package scaffold for the Linux
`hid-logitech-dj` driver for quick local iteration and testing.

This branch follows [this patch series](https://lore.kernel.org/linux-input/20261002-bolt-input-rfc-v1-0-333e1f350586@gmail.com/) from the LKML.

## Build and install (Arch)

```bash
makepkg -si
```

This installs sources under `/usr/src/hid-logitech-dj-bolt-dkms-<version>/` for DKMS.

## Manual DKMS install on other distros

```bash
sudo dkms add -m hid-logitech-dj-bolt -v <version>
sudo dkms build -m hid-logitech-dj-bolt -v <version>
sudo dkms install -m hid-logitech-dj-bolt -v <version>
```
