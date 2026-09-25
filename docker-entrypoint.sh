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
    local copied_paths=()

    for allowed_file in hosts.yml config.yml; do
        source_path="${source_dir}/${allowed_file}"
        target_path="${target_dir}/${allowed_file}"

        if [ -L "${source_path}" ]; then
            echo "Refusing to seed GitHub CLI config from ${source_dir}: ${allowed_file} must not be a symlink." >&2
            exit 1
        fi

        if [ -f "${source_path}" ] && [ ! -e "${target_path}" ]; then
            install -D -m 644 "${source_path}" "${target_path}"
            copied_paths+=("${target_path}")
        fi
    done

    if [ "${#copied_paths[@]}" -gt 0 ]; then
        printf '%s\n' "${copied_paths[@]}"
    fi
}

if [ -e "${host_gh_config_dir}/hosts.yml" ] || [ -L "${host_gh_config_dir}/hosts.yml" ] \
    || [ -e "${host_gh_config_dir}/config.yml" ] || [ -L "${host_gh_config_dir}/config.yml" ]; then
    host_gh_config_available=true
fi

if [ "$#" -eq 0 ]; then
    set -- bash
fi

if [ "$(id -u)" -eq 0 ] && id "${runtime_user}" >/dev/null 2>&1; then
    copied_files=""
    install -d -m 755 -o "${runtime_user}" -g "${runtime_user}" "${gh_config_dir}"
    chown "${runtime_user}:${runtime_user}" "${gh_config_dir}"
    if [ "${host_gh_config_available}" = true ]; then
        copied_files="$(copy_host_gh_config "${host_gh_config_dir}" "${gh_config_dir}")"
        if [ -n "${copied_files}" ]; then
            while IFS= read -r copied_file; do
                [ -n "${copied_file}" ] || continue
                chown "${runtime_user}:${runtime_user}" "${copied_file}"
            done <<< "${copied_files}"
        fi
    fi
    exec sudo -E -H -u "${runtime_user}" -- "$@"
fi

if [ "${host_gh_config_available}" = true ]; then
    mkdir -p "${gh_config_dir}"
    copy_host_gh_config "${host_gh_config_dir}" "${gh_config_dir}"
fi

exec "$@"
