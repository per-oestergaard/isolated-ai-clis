#!/usr/bin/env bash
set -euo pipefail

host_gh_config_dir="${HOST_GH_CONFIG_DIR:-/host-gh}"
gh_config_dir="${GH_CONFIG_DIR:-$HOME/.config/gh}"
runtime_user="${CONTAINER_RUN_USER:-vscode}"
host_gh_config_available=false

copy_host_gh_config() {
    local source_dir="$1"
    local target_dir="$2"
    local allowed_file
    local source_path
    local target_path

    for allowed_file in hosts.yml config.yml; do
        source_path="${source_dir}/${allowed_file}"
        target_path="${target_dir}/${allowed_file}"

        if [ -L "${source_path}" ]; then
            echo "Refusing to seed GitHub CLI config from ${source_dir}: ${allowed_file} must not be a symlink." >&2
            exit 1
        fi

        if [ -f "${source_path}" ] && [ ! -e "${target_path}" ]; then
            install -D -m "$(stat -c '%a' "${source_path}")" "${source_path}" "${target_path}"
        fi
    done
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
