#!/usr/bin/env bash
set -euo pipefail

host_gh_config_dir="${HOST_GH_CONFIG_DIR:-/host-gh}"
gh_config_dir="${GH_CONFIG_DIR:-$HOME/.config/gh}"
runtime_user="${CONTAINER_RUN_USER:-vscode}"
host_gh_config_available=false

copy_host_gh_config() {
    local source_dir="$1"
    local target_dir="$2"
    local relative_path
    local source_path
    local target_path

    if find "${source_dir}" -type l -print -quit | grep -q .; then
        echo "Refusing to seed GitHub CLI config from ${source_dir}: symlinks are not allowed." >&2
        exit 1
    fi

    while IFS= read -r relative_path; do
        source_path="${source_dir}/${relative_path}"
        target_path="${target_dir}/${relative_path}"

        if [ -d "${source_path}" ]; then
            mkdir -p "${target_path}"
        elif [ -f "${source_path}" ] && [ ! -e "${target_path}" ]; then
            mkdir -p "$(dirname "${target_path}")"
            install -m 600 "${source_path}" "${target_path}"
        fi
    done < <(cd "${source_dir}" && find . -mindepth 1 | sort)
}

if [ -d "${host_gh_config_dir}" ] && [ -n "$(find "${host_gh_config_dir}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    host_gh_config_available=true
fi

if [ "$#" -eq 0 ]; then
    set -- bash
fi

if [ "$(id -u)" -eq 0 ] && id "${runtime_user}" >/dev/null 2>&1; then
    install -d -m 755 -o "${runtime_user}" -g "${runtime_user}" "${gh_config_dir}"
    if [ "${host_gh_config_available}" = true ]; then
        copy_host_gh_config "${host_gh_config_dir}" "${gh_config_dir}"
        chown -R "${runtime_user}:${runtime_user}" "${gh_config_dir}"
    fi
    exec sudo -E -H -u "${runtime_user}" -- "$@"
fi

if [ "${host_gh_config_available}" = true ]; then
    mkdir -p "${gh_config_dir}"
    copy_host_gh_config "${host_gh_config_dir}" "${gh_config_dir}"
fi

exec "$@"
