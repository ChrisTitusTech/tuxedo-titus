#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "${script_dir}/lib.sh"

load_config
require_fedora_host
require_source_tree "${TUXEDO_CONTROL_CENTER_DIR}" "control center" package.json package-lock.json build-src/electron-builder.ts src/dist-data/tccd.service
need_cmd npm

info "Building TUXEDO Control Center RPM in ${TUXEDO_CONTROL_CENTER_DIR}"
if [[ ! -d "${TUXEDO_CONTROL_CENTER_DIR}/node_modules" || "${TCC_NPM_INSTALL:-0}" == "1" ]]; then
    npm --prefix "${TUXEDO_CONTROL_CENTER_DIR}" clean-install
fi

npm --prefix "${TUXEDO_CONTROL_CENTER_DIR}" run pack-prod -- rpm

rpm_path="$(newest_tcc_rpm)"
[[ -n "${rpm_path}" ]] || die "no RPM produced under ${TUXEDO_CONTROL_CENTER_DIR}/dist/packages"
info "Built RPM: ${rpm_path}"
