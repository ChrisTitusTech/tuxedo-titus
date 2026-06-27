# TUXEDO InfinityBook Pro Gen7 Fedora Drivers

Personal Fedora-focused driver tree for this laptop:

- Vendor: `TUXEDO`
- Model: `TUXEDO InfinityBook Pro Gen7 (MK1)`
- SKU: `IBP1XI07MK1`
- Board: `PHxARX1_PHxAQF1`
- Touchpad: `UNIW0001:00 093A:0274`
- Verified kernel: `7.0.12-201.fc44.x86_64`

This repository was reduced from the upstream multi-device `tuxedo-drivers`
tree to the pieces that are useful on this hardware.

## Included Kernel Modules

- `tuxedo_compatibility_check`
- `tuxedo_keyboard`
- `uniwill_wmi`
- `tuxedo_io`

These expose the verified local interfaces:

- `TUXEDO Keyboard` input device
- `white:kbd_backlight`
- `fn_lock`
- `charging_profile`
- `charging_priority`
- Uniwill WMI I/O through `/dev/tuxedo_io`

Fedora's upstream `uniwill_laptop` conflicts with this stack. The installed
modprobe rule blacklists it so `tuxedo_keyboard` and `uniwill_wmi` can bind.

## Touchpad Firmware Control

The physical touchpad is handled by Fedora's normal HID stack:

- kernel path: `i2c-UNIW0001:00`
- HID device: `0018:093A:0274.0001`
- hidraw node: `/dev/hidraw0` on this machine
- kernel driver: `hid-multitouch`

TUXEDO's separate `tuxedo-touchpad-switch` project fixes the disabled-touchpad
LED by writing Microsoft's touchpad selective-reporting feature over hidraw.
This repo includes a local, desktop-agnostic implementation:

```bash
tuxedo-touchpad status
tuxedo-touchpad off
tuxedo-touchpad on
```

The command searches for the `i2c-UNIW0001:00` hidraw device, locates the
surface-button-switch feature report in the HID descriptor, then writes:

- `0x03` to enable touch and clicks, with the disabled LED off
- `0x00` to disable touch and clicks, with the disabled LED on

The installed udev rule gives write access to this specific `UNIW0001` hidraw
device. Another udev rule makes libinput ignore the bogus companion mouse node
for `093A:0274` while keeping the real touchpad node.

## Build

Install Fedora build dependencies:

```bash
sudo dnf install dkms gcc make systemd-devel "kernel-devel-uname-r == $(uname -r)"
```

Build the touchpad helper and kernel modules:

```bash
make clean
make
```

## Manual Runtime Test

Unload Fedora's upstream driver and load the local modules:

```bash
sudo modprobe -r uniwill_laptop
sudo modprobe led-class-multicolor
sudo insmod src/tuxedo_compatibility_check/tuxedo_compatibility_check.ko
sudo insmod src/tuxedo_keyboard.ko
sudo insmod src/uniwill_wmi.ko
sudo insmod src/tuxedo_io/tuxedo_io.ko
```

Verify exposed hardware controls:

```bash
cat /sys/devices/platform/tuxedo_keyboard/input/input*/name
cat /sys/class/leds/white:kbd_backlight/max_brightness
cat /sys/devices/platform/tuxedo_keyboard/fn_lock
cat /sys/devices/platform/tuxedo_keyboard/charging_profile/charging_profiles_available
cat /sys/devices/platform/tuxedo_keyboard/charging_priority/charging_prios_available
build/tuxedo-touchpad status
```

Restore Fedora's default driver after a manual test:

```bash
sudo rmmod tuxedo_io uniwill_wmi tuxedo_keyboard tuxedo_compatibility_check
sudo modprobe uniwill_laptop
```

## Install

```bash
sudo make install
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=hidraw --subsystem-match=input
```

`make install` installs the touchpad helper and udev/modprobe files, then
registers this source tree with DKMS as `tuxedo-ibp-gen7-drivers`. DKMS builds
and installs the four kernel modules for the active kernel under
`/lib/modules/$(uname -r)/updates/dkms/`.

Verify DKMS registration:

```bash
dkms status tuxedo-ibp-gen7-drivers
modinfo tuxedo_keyboard | grep ^filename
```

Fedora's DKMS package installs `/usr/lib/kernel/install.d/40-dkms.install`,
which runs `dkms kernel_postinst --kernelver <new-kernel>` during kernel
installation. Fedora also enables `dkms.service`, which runs
`dkms autoinstall --kernelver %v` at boot as a fallback. With `AUTOINSTALL=yes`
in `dkms.conf`, a newly installed Fedora kernel will build these modules
automatically once that kernel has matching `kernel-devel` headers installed.
Fedora's kernel packages normally pull in matching headers when
`kernel-devel-matched` is installed; otherwise install the matching package:

```bash
sudo dnf install kernel-devel-matched
```

Reboot after the first install so the `uniwill_laptop` blacklist and module
autoload order are applied cleanly.

## Removed Upstream Hardware Support

This personal tree intentionally removed source and packaging for hardware not
present on this laptop:

- Clevo ACPI/WMI modules
- ITE keyboard/lightbar modules
- NB04/NB05/TUXI platform collections
- NVIDIA NB02 dynamic-boost module
- STK8321/GXTP7380 tablet and sensor support
- non-Fedora package-test dependency targets
- unrelated udev quirks for LTE, InfinityFlex touchpanel, Realtek card reader,
  Pulse NVMe wake, and systemd LED boot delay

Keep upstream `tuxedo-drivers` as the source for those devices.
