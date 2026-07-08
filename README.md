# hid-logitech-dj-bolt-dkms

This directory contains an out-of-tree DKMS package scaffold for the Linux
`hid-logitech-dj` driver for quick local iteration and testing.

## Files

- `hid-logitech-dj.c`: Driver source copied from `drivers/hid/`
- `hid-ids.h`: Header copied from `drivers/hid/`
- `Makefile`: Out-of-tree module build rules
- `dkms.conf`: DKMS metadata
- `PKGBUILD`: Arch Linux package recipe (emphasis quick and local)

## Build and install (Arch)

```bash
makepkg -si
```

This installs source under `/usr/src/hid-logitech-dj-bolt-dkms-<version>/` for DKMS.

## Manual DKMS install

```bash
sudo dkms add -m hid-logitech-dj-bolt -v <version>
sudo dkms build -m hid-logitech-dj-bolt -v <version>
sudo dkms install -m hid-logitech-dj-bolt -v <version>
```
