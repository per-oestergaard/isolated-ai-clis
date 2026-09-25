FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG GH_COPILOT_VERSION=v1.2.0

ENV DEBIAN_FRONTEND=noninteractive \
    GH_CONFIG_DIR=/home/vscode/.config/gh

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends gh nodejs npm \
    && npm install -g @anthropic-ai/claude-code \
    && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p /home/vscode/.config/gh \
    && arch="$(dpkg --print-architecture)" \
    && case "${arch}" in \
        amd64) gh_copilot_asset="linux-amd64" ;; \
        arm64) gh_copilot_asset="linux-arm64" ;; \
        armhf) gh_copilot_asset="linux-arm" ;; \
        *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
       esac \
    && mkdir -p /home/vscode/.local/share/gh/extensions/gh-copilot \
    && gh_copilot_download="$(mktemp)" \
    && curl -fsSL "https://github.com/github/gh-copilot/releases/download/${GH_COPILOT_VERSION}/${gh_copilot_asset}" \
        -o "${gh_copilot_download}" \
    && if gzip -t "${gh_copilot_download}" 2>/dev/null; then \
           gzip -dc "${gh_copilot_download}" > /home/vscode/.local/share/gh/extensions/gh-copilot/gh-copilot; \
       else \
           mv "${gh_copilot_download}" /home/vscode/.local/share/gh/extensions/gh-copilot/gh-copilot; \
       fi \
    && rm -f "${gh_copilot_download}" \
    && chmod 755 /home/vscode/.local/share/gh/extensions/gh-copilot/gh-copilot \
    && chown -R vscode:vscode /home/vscode/.config /home/vscode/.local

VOLUME ["/home/vscode/.config/gh"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
