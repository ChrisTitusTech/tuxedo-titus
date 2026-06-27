# Install Runbook

## Preflight

```bash
make check
make doctor
```

`make doctor` should report Fedora, the TUXEDO InfinityBook Pro Gen7 DMI data,
the driver source path, and the Control Center source path.

## Install Dependencies

```bash
make install-deps
```

This uses `sudo dnf install` for Fedora build dependencies, DKMS, Node/npm, and
RPM packaging tools.

## Drivers

```bash
make build-drivers
make install-drivers
```

Expected evidence:

```bash
dkms status tuxedo-ibp-gen7-drivers
modinfo tuxedo_keyboard
tuxedo-touchpad status
```

Reboot after the first driver install so the `uniwill_laptop` blacklist and
module load order apply cleanly.

## Control Center

```bash
make build-control-center
make install-control-center
```

If Fedora rejects the generated upstream RPM because its dependency names are
not Fedora-native, review the missing dependencies, install Fedora equivalents,
then run:

```bash
scripts/install-control-center.sh --nodeps
```

Expected evidence:

```bash
systemctl status tccd
systemctl status tccd-sleep
```

