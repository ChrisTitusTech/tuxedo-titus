#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

load_config() {
    # shellcheck disable=SC1091
    source "${repo_root}/config/defaults.env"
    if [[ -f "${repo_root}/config/local.env" ]]; then
        # shellcheck disable=SC1091
        source "${repo_root}/config/local.env"
    fi

    if [[ ! -d "${TUXEDO_DRIVERS_DIR}" && -d "/home/titus/github/tuxedo-drives" ]]; then
        TUXEDO_DRIVERS_DIR="/home/titus/github/tuxedo-drives"
    fi
}

info() {
    printf '==> %s\n' "$*"
}

warn() {
    printf 'warning: %s\n' "$*" >&2
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

require_source_tree() {
    local path="$1"
    local name="$2"
    shift 2

    [[ -d "${path}" ]] || die "${name} source tree not found: ${path}"

    local required
    for required in "$@"; do
        [[ -e "${path}/${required}" ]] || die "${name} source tree missing ${required}: ${path}"
    done
}

require_fedora_host() {
    local os_id=""
    local version_id=""
    # shellcheck disable=SC1091
    source /etc/os-release
    os_id="${ID:-}"
    version_id="${VERSION_ID:-}"

    if [[ "${ALLOW_UNSUPPORTED_HOST:-0}" == "1" ]]; then
        warn "ALLOW_UNSUPPORTED_HOST=1 set; skipping strict host checks"
        return 0
    fi

    [[ "${os_id}" == "fedora" ]] || die "expected Fedora, found ID=${os_id}"
    [[ "$(uname -m)" == "x86_64" ]] || die "expected x86_64, found $(uname -m)"

    local vendor=""
    local product=""
    local sku=""
    vendor="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
    product="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
    sku="$(cat /sys/class/dmi/id/product_sku 2>/dev/null || true)"

    [[ "${vendor}" == "TUXEDO" ]] || die "expected TUXEDO vendor, found ${vendor:-unknown}"
    [[ "${sku}" == "IBP1XI07MK1" ]] || die "expected SKU IBP1XI07MK1, found ${sku:-unknown}"

    info "Host: Fedora ${version_id}, $(uname -r), ${vendor} ${product}, SKU ${sku}"
}

sudo_cmd() {
    if [[ "${SUDO:-sudo}" == "" ]]; then
        "$@"
    else
        "${SUDO}" "$@"
    fi
}

newest_tcc_rpm() {
    find "${TUXEDO_CONTROL_CENTER_DIR}/dist/packages" -maxdepth 1 -type f -name '*.rpm' \
        -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk 'NR == 1 {print $2}'
}
