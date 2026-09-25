#!/usr/bin/env bash
set -euo pipefail

host_gh_config_dir="${HOST_GH_CONFIG_DIR:-/host-gh}"
gh_config_dir="${GH_CONFIG_DIR:-$HOME/.config/gh}"
runtime_user="${CONTAINER_RUN_USER:-vscode}"

if [ -d "${host_gh_config_dir}" ] && [ -n "$(find "${host_gh_config_dir}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    mkdir -p "${gh_config_dir}"
    cp -R --update=none "${host_gh_config_dir}/." "${gh_config_dir}/" || true
fi

if [ "$#" -eq 0 ]; then
    set -- bash
fi

if [ "$(id -u)" -eq 0 ] && id "${runtime_user}" >/dev/null 2>&1; then
    mkdir -p "${gh_config_dir}"
    chown -R "${runtime_user}:${runtime_user}" "${gh_config_dir}"
    exec sudo -E -H -u "${runtime_user}" -- "$@"
fi

exec "$@"
