FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG GH_COPILOT_VERSION=1.2.0

ENV DEBIAN_FRONTEND=noninteractive \
    GH_CONFIG_DIR=/home/vscode/.config/gh

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh nodejs npm \
    && npm install -g @anthropic-ai/claude-code \
    && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p /home/vscode/.config/gh \
    && arch="$(dpkg --print-architecture)" \
    && gh_copilot_version="${GH_COPILOT_VERSION#v}" \
    && gh_copilot_tag="v${gh_copilot_version}" \
    && case "${arch}" in \
        amd64) \
            gh_copilot_asset="linux-amd64"; \
            gh_copilot_sha256="5956f7da0f5eaa879082f3d418e43baf7a03f8f7ab298416121fcfa19c15aa42" \
            ;; \
        arm64) \
            gh_copilot_asset="linux-arm64"; \
            gh_copilot_sha256="9d983bbb405420739dbb7760dbc7f27609ba72daf88ce38864e0399acdff13ae" \
            ;; \
        armhf) \
            gh_copilot_asset="linux-arm"; \
            gh_copilot_sha256="6424c9a23bfc9d42e838d82b9ee419f3383e4af65dde7e81255f50f73e946c31" \
            ;; \
        *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
       esac \
    && mkdir -p /home/vscode/.local/share/gh/extensions/gh-copilot \
    && gh_copilot_download="$(mktemp)" \
    && curl -fsSL "https://github.com/github/gh-copilot/releases/download/${gh_copilot_tag}/${gh_copilot_asset}" \
        -o "${gh_copilot_download}" \
    && echo "${gh_copilot_sha256}  ${gh_copilot_download}" | sha256sum -c - \
    && if gzip -t "${gh_copilot_download}" 2>/dev/null; then \
           gzip -dc "${gh_copilot_download}" > /home/vscode/.local/share/gh/extensions/gh-copilot/gh-copilot; \
           rm -f "${gh_copilot_download}"; \
       else \
           mv "${gh_copilot_download}" /home/vscode/.local/share/gh/extensions/gh-copilot/gh-copilot; \
       fi \
    && chmod 755 /home/vscode/.local/share/gh/extensions/gh-copilot/gh-copilot \
    && chown -R vscode:vscode /home/vscode/.config /home/vscode/.local

VOLUME ["/home/vscode/.config/gh"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
