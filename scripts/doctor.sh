#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "${script_dir}/lib.sh"

load_config

require_fedora_host
require_source_tree "${TUXEDO_DRIVERS_DIR}" "drivers" Makefile dkms.conf src files/usr
require_source_tree "${TUXEDO_CONTROL_CENTER_DIR}" "control center" package.json package-lock.json build-src/electron-builder.ts src/dist-data/tccd.service

info "Drivers: ${TUXEDO_DRIVERS_DIR}"
info "Control Center: ${TUXEDO_CONTROL_CENTER_DIR}"

if command -v dkms >/dev/null 2>&1; then
    dkms status tuxedo-ibp-gen7-drivers || true
else
    warn "dkms is not installed"
fi

if command -v node >/dev/null 2>&1; then
    info "Node: $(node --version)"
else
    warn "node is not installed"
fi

if command -v npm >/dev/null 2>&1; then
    info "npm: $(npm --version)"
else
    warn "npm is not installed"
fi
