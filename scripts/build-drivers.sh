#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "${script_dir}/lib.sh"

load_config
require_fedora_host
require_source_tree "${TUXEDO_DRIVERS_DIR}" "drivers" Makefile dkms.conf src files/usr

info "Building drivers in ${TUXEDO_DRIVERS_DIR}"
make -C "${TUXEDO_DRIVERS_DIR}" clean
make -C "${TUXEDO_DRIVERS_DIR}"
