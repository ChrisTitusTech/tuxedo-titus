# tuxedo-titus

Fedora install automation for this TUXEDO InfinityBook Pro Gen7 laptop.

This repo coordinates the local driver checkout and TUXEDO Control Center
checkout without vendoring either project.

## Quick Start

```bash
make doctor
make install-deps
make build-drivers
make install-drivers
make build-control-center
make install-control-center
```

To run everything in order:

```bash
make install
```

## Paths

Defaults are defined in `config/defaults.env`:

- `TUXEDO_DRIVERS_DIR=/home/titus/github/tuxedo-drivers`
- `TUXEDO_CONTROL_CENTER_DIR=/home/titus/github/tuxedo-control-center`

Create `config/local.env` for machine-local overrides.

## Common Targets

- `make check`: syntax and repository validation.
- `make doctor`: host and source-tree diagnostics.
- `make install-deps`: Fedora packages needed for drivers and TCC builds.
- `make build-drivers`: build the DKMS modules and touchpad helper.
- `make install-drivers`: install driver assets and DKMS modules.
- `make build-control-center`: build the TCC RPM.
- `make install-control-center`: install the newest local TCC RPM.

See [SPEC.md](SPEC.md) for the full contract.

