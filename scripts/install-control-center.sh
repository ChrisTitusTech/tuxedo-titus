#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "${script_dir}/lib.sh"

usage() {
    cat <<'USAGE'
Usage: scripts/install-control-center.sh [--nodeps]

Installs the newest TUXEDO Control Center RPM from dist/packages.
Use --nodeps only if Fedora cannot resolve the upstream RPM dependency names
and equivalent Fedora packages have already been reviewed/installed.
USAGE
}

nodeps=0
while (($#)); do
    case "$1" in
    --nodeps)
        nodeps=1
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        die "unknown argument: $1"
        ;;
    esac
    shift
done

load_config
require_fedora_host
require_source_tree "${TUXEDO_CONTROL_CENTER_DIR}" "control center" package.json package-lock.json build-src/electron-builder.ts src/dist-data/tccd.service

rpm_path="$(newest_tcc_rpm)"
[[ -n "${rpm_path}" ]] || die "no RPM found; run scripts/build-control-center.sh first"

info "Installing TUXEDO Control Center RPM: ${rpm_path}"
if [[ "${nodeps}" == "1" ]]; then
    sudo_cmd rpm -Uvh --replacepkgs --nodeps "${rpm_path}"
else
    sudo_cmd dnf install -y "${rpm_path}"
fi

info "Enabling TUXEDO Control Center services"
sudo_cmd systemctl daemon-reload
sudo_cmd systemctl enable --now tccd.service tccd-sleep.service
systemctl --no-pager --full status tccd.service || true
