#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
    AGENTS.md
    SPEC.md
    README.md
    Makefile
    config/defaults.env
    scripts/lib.sh
    scripts/doctor.sh
    scripts/install-deps.sh
    scripts/build-drivers.sh
    scripts/install-drivers.sh
    scripts/build-control-center.sh
    scripts/install-control-center.sh
    scripts/install-all.sh
    scripts/validate.sh
)

for file in "${required_files[@]}"; do
    [[ -f "${repo_root}/${file}" ]] || {
        printf 'missing required file: %s\n' "${file}" >&2
        exit 1
    }
done

while IFS= read -r script; do
    bash -n "${script}"
done < <(find "${repo_root}/scripts" -maxdepth 1 -type f -name '*.sh' | sort)

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${repo_root}"/scripts/*.sh
else
    printf 'warning: shellcheck not installed; skipped static shell analysis\n' >&2
fi

if command -v shfmt >/dev/null 2>&1; then
    shfmt -d "${repo_root}"/scripts/*.sh
else
    printf 'warning: shfmt not installed; skipped formatting check\n' >&2
fi

printf 'validation passed\n'
