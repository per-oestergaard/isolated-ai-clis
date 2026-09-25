# isolated-ai-clis
gh copilot, claude - without polluting my local machine

## Build the image

```bash
docker build -t local/isolated-ai-clis .
```

## Run the CLIs

The image entrypoint runs whichever CLI command you pass in:

`gh copilot ...` commands require GitHub CLI auth first. Use one of the auth options in the next section before running Copilot commands in a fresh container.

```bash
docker run -it --rm local/isolated-ai-clis gh --version
docker run -it --rm local/isolated-ai-clis gh copilot suggest -t shell "list all files"
docker run -it --rm local/isolated-ai-clis claude
```

## GitHub auth

If the mounted host config directory contains `hosts.yml` or `config.yml`, the container seeds any missing copies of those files into `GH_CONFIG_DIR`. If neither file is present, it just uses the writable `GH_CONFIG_DIR` inside the container.

For a plain `docker run`, mount whichever auth source you prefer:

```bash
# Reuse the host gh auth
docker run -it --rm \
  -v "$HOME/.config/gh:/host-gh:ro" \
  local/isolated-ai-clis gh auth status

# Or persist auth in a Docker volume
docker run -it --rm \
  -v isolated-ai-clis-gh:/home/vscode/.config/gh \
  local/isolated-ai-clis gh auth login
```

## Devcontainer

`.devcontainer/devcontainer.json` builds from the same `Dockerfile` and mounts:

- your host home directory read-only at `/host-home`, with `HOST_GH_CONFIG_DIR` set to `/host-home/.config/gh`
- a named Docker volume at `/home/vscode/.config/gh`

That lets the container seed the writable GH config from the host when available, while still working with a Docker-managed volume when it is not.
