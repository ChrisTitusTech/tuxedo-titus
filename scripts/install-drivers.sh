#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "${script_dir}/lib.sh"

load_config
require_fedora_host
require_source_tree "${TUXEDO_DRIVERS_DIR}" "drivers" Makefile dkms.conf src files/usr
need_cmd dkms

info "Installing DKMS drivers from ${TUXEDO_DRIVERS_DIR}"
sudo_cmd make -C "${TUXEDO_DRIVERS_DIR}" install

info "Reloading udev rules"
sudo_cmd udevadm control --reload
sudo_cmd udevadm trigger --subsystem-match=hidraw --subsystem-match=input

info "Driver install status"
dkms status tuxedo-ibp-gen7-drivers || true
modinfo tuxedo_keyboard | sed -n '1,12p' || true
