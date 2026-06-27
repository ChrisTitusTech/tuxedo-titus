#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "${script_dir}/lib.sh"

load_config
require_fedora_host
need_cmd dnf

packages=(
    autoconf
    automake
    dkms
    gcc
    gcc-c++
    git
    kernel-devel-matched
    kernel-headers
    libudev-devel
    make
    nodejs
    npm
    pkgconf-pkg-config
    python3
    rpm
    rpm-build
    systemd-devel
)

info "Installing Fedora build dependencies"
sudo_cmd dnf install -y "${packages[@]}"
