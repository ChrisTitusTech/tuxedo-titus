# tuxedo-titus Specification

## Purpose

`tuxedo-titus` is a host-local automation repository for building and
installing the TUXEDO laptop support stack on this Fedora laptop. It carries the
source files needed by its scripts under `vendor/`:

- `vendor/tuxedo-drivers`: laptop-specific DKMS kernel modules,
  modprobe rules, udev rules, and the local `tuxedo-touchpad` helper.
- `vendor/tuxedo-control-center`: TUXEDO Control Center GUI and daemon, built as
  an RPM from the local source copy.

The vendored directories are source snapshots for this machine. Generated
dependencies and build outputs such as `node_modules/`, `build/`, and `dist/`
remain untracked.

## Host Contract

The supported host is:

- Vendor: `TUXEDO`
- Model: `TUXEDO InfinityBook Pro Gen7 (MK1)`
- SKU: `IBP1XI07MK1`
- OS family: Fedora
- Architecture: `x86_64`

The scripts read `/etc/os-release` and DMI data from `/sys/class/dmi/id`. By
default, install operations stop when the host does not match. Set
`ALLOW_UNSUPPORTED_HOST=1` only for deliberate testing.

## Driver Contract

The driver source tree must provide:

- `Makefile`
- `dkms.conf`
- `src/`
- `files/usr/`
- optional `tools/tuxedo-touchpad.c`

The expected DKMS package is:

- name: `tuxedo-ibp-gen7-drivers`
- modules:
  - `tuxedo_compatibility_check`
  - `tuxedo_keyboard`
  - `uniwill_wmi`
  - `tuxedo_io`

Driver install flow:

1. Install Fedora build dependencies.
2. Run `make clean` in the driver tree when requested.
3. Run `make` in the driver tree.
4. Run `sudo make install` in the driver tree.
5. Reload udev and trigger `hidraw` and `input`.
6. Validate DKMS status and installed module metadata.

Fedora's upstream `uniwill_laptop` driver conflicts with this stack. The driver
tree's modprobe rules are responsible for blacklisting it.

## Control Center Contract

The Control Center source tree must provide:

- `package.json`
- `package-lock.json`
- `build-src/electron-builder.ts`
- `src/dist-data/tccd.service`
- NPM scripts `build-prod` and `pack-prod`

Control Center build flow:

1. Install Fedora build dependencies.
2. Run `npm clean-install` if `node_modules` is absent or
   `TCC_NPM_INSTALL=1`.
3. Run `npm run pack-prod -- rpm`.
4. Locate the newest RPM under `dist/packages`.
5. Install the RPM with `sudo dnf install`.
6. Enable and start `tccd` and `tccd-sleep`.

The upstream RPM metadata is not Fedora-specific. If dependency names do not
resolve on Fedora, use `scripts/install-control-center.sh --nodeps` only after
reviewing the generated RPM and installing equivalent Fedora libraries manually.

## Configuration

Defaults:

```bash
TUXEDO_DRIVERS_DIR="${repo_root}/vendor/tuxedo-drivers"
TUXEDO_CONTROL_CENTER_DIR="${repo_root}/vendor/tuxedo-control-center"
SUDO=sudo
```

Local overrides belong in `config/local.env`, which is ignored by Git.

## Acceptance Criteria

- `make check` passes.
- `make doctor` confirms Fedora, TUXEDO DMI data, and both source trees.
- `make build-drivers` builds the DKMS modules for the running kernel.
- `make install-drivers` registers and installs
  `tuxedo-ibp-gen7-drivers` through DKMS.
- `make build-control-center` produces a local RPM.
- `make install-control-center` installs the RPM and starts the daemon units.
- `tuxedo-touchpad status`, `dkms status`, `modinfo tuxedo_keyboard`, and
  `systemctl status tccd` provide healthy runtime evidence.
