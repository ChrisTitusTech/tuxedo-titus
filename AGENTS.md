# Repository Instructions

This repository configures this Fedora laptop with the local TUXEDO driver tree
and TUXEDO Control Center checkout.

## Scope

- Target host: TUXEDO InfinityBook Pro Gen7 (MK1), SKU `IBP1XI07MK1`.
- Target OS: Fedora Linux 44 or newer Fedora releases, `x86_64`.
- Driver source default: `vendor/tuxedo-drivers`.
- Control Center source default: `vendor/tuxedo-control-center`.
- Override `TUXEDO_DRIVERS_DIR` or `TUXEDO_CONTROL_CENTER_DIR` only when
  deliberately testing another checkout.

## Safety

- Keep generated dependencies and build output out of Git, especially
  `vendor/tuxedo-control-center/node_modules`, `vendor/tuxedo-control-center/build`,
  `vendor/tuxedo-control-center/dist`, and kernel build artifacts under
  `vendor/tuxedo-drivers`.
- Treat `scripts/install-*` and `make install-*` targets as privileged host
  operations because they install packages, DKMS modules, udev rules, DBus
  policy, and systemd units.
- Preserve unrelated changes in the vendored source trees.
- Do not disable SELinux or weaken system security to make installs pass.
- Keep destructive cleanup limited to generated build artifacts and documented
  package paths.

## Development

- Use `make check` before committing.
- Shell scripts use Bash and should pass `bash -n`; run ShellCheck when
  installed.
- Keep scripts small, explicit, and idempotent where the underlying tools allow.
- Prefer environment overrides in `config/local.env` over editing scripts:
  `TUXEDO_DRIVERS_DIR`, `TUXEDO_CONTROL_CENTER_DIR`, `SUDO`, and
  `ALLOW_UNSUPPORTED_HOST`.

## Runtime Validation

After installing drivers:

- `dkms status tuxedo-ibp-gen7-drivers`
- `modinfo tuxedo_keyboard`
- `tuxedo-touchpad status`
- Check `/sys/devices/platform/tuxedo_keyboard/` for keyboard, charging, and
  fan-control interfaces.

After installing Control Center:

- `systemctl status tccd`
- `systemctl status tccd-sleep`
- Launch `tuxedo-control-center` from the desktop or command line.
