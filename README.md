# orca-devcontainer

Public Docker image that runs [`orca serve`](https://github.com/stablyai/orca) with `asdf` and an SSH server. Published at `ghcr.io/washingtonj/orca-devcontainer`.

The image follows the official [Headless Linux Server](https://github.com/stablyai/orca/blob/main/docs/reference/headless-linux-server.md) guide.

## Quick start

Pull and run:

```bash
docker run -d --name orca \
  -p 2222:22 \
  -e ORCA_PAIRING_ADDRESS=127.0.0.1 \
  -v orca-home:/home/agent \
  ghcr.io/washingtonj/orca-devcontainer:latest

docker logs -f orca   # grab the pairing URL
```

Or copy `docker-compose.yml`, adjust `.env`, then:

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f
```

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `ORCA_PAIRING_ADDRESS` | (required) | Address the Orca client uses to reach this server. Not a bind address. Wildcards (`*`, `0.0.0.0`, `::`) are not accepted by `orca serve`. |
| `ORCA_PORT` | `6768` | Internal port for `orca serve` |
| `ORCA_JSON` | `0` | Pass `--json` to `serve` (single-line readiness contract) |
| `ORCA_MOBILE_PAIRING` | `0` | Enable `--mobile-pairing` |
| `ORCA_NO_SANDBOX` | `0` | Sets `ELECTRON_DISABLE_SANDBOX=1`. Only enable if Chromium reports sandbox errors. |

`ORCA_PAIRING_ADDRESS` examples:

| Scenario | Value |
|---|---|
| Same machine | `127.0.0.1` |
| LAN | `192.168.1.50` |
| Tailscale | `100.64.1.20` |
| Reverse proxy | `https://orca.example.com/runtime` |

## Persistence

Mount a volume at `/home/agent`. The volume holds:

- `.asdf/` — installed toolchains (asdf plugins and language versions)
- `.config/orca/` — Orca runtime state, paired-device keys
- `.ssh/` — SSH host key, generated client key, and `authorized_keys` for the `agent` user
- `workspace/` — accessible at `/workspace` via symlink

Without a volume, all of this is lost on container recreation.

## SSH

Container exposes port 22. Only public-key authentication is enabled; password auth, PAM, and root login are disabled.

On first boot the container generates a **client keypair** and stores it in the volume. Pull the private key out and use it to connect:

```bash
docker cp orca:/home/agent/.ssh/id_ed25519_client ~/.ssh/orca_client_key
chmod 600 ~/.ssh/orca_client_key

ssh -p 2222 -i ~/.ssh/orca_client_key agent@<docker-host>
```

To use your own key instead of the generated one, append its public half to `/home/agent/.ssh/authorized_keys`:

```bash
docker exec orca bash -c 'cat >> /home/agent/.ssh/authorized_keys' < ~/.ssh/your_key.pub
docker exec orca bash -c 'chmod 600 /home/agent/.ssh/authorized_keys && chown agent:agent /home/agent/.ssh/authorized_keys'
```

The generated key remains authorized when you add your own, so you can keep both or remove it later.

## Toolchains (asdf)

The image installs `asdf` (no plugins). Install languages at any time:

```bash
docker exec -u agent -it orca bash -lc \
  'asdf plugin add nodejs && asdf install nodejs latest && asdf set -u nodejs latest'
```

Any [asdf plugin](https://github.com/asdf-vm/asdf-plugins) works (`go`, `deno`, `python`, `rust`, ...). Installations persist in the volume across container recreation.

## Network security

The image exposes port `6768` (`orca serve`) and port `22` (sshd). Treat both as administrative ports — **do not expose on the public internet**.

The Orca documentation reinforces the same point:

> "Do not publish this port on the public internet; prefer Tailscale / WireGuard / trusted LAN."
> — [Headless Linux Server](https://github.com/stablyai/orca/blob/main/docs/reference/headless-linux-server.md)

> "Wildcard addresses such as `*`, `0.0.0.0`, and `::` cannot be advertised."

Recommended: Tailscale, WireGuard, or bind only to `127.0.0.1` / your LAN. If you reverse-proxy, the proxy must support WebSocket upgrade and route the advertised path; advertise `wss://` (or `https://`) when TLS terminates at the proxy.

Orca runs as unprivileged user `agent` (uid 1000); sshd runs as root for privilege separation — matching the [official guide](https://github.com/stablyai/orca/blob/main/docs/reference/headless-linux-server.md).

## Upgrade

```bash
docker compose pull
docker compose up -d
```

The volume is preserved. Orca migrates its on-disk state forward across upgrades.

## Troubleshooting

| Symptom | What to try |
|---|---|
| No pairing URL in logs | Verify `ORCA_PAIRING_ADDRESS` is reachable from the client (not `0.0.0.0`) |
| Client cannot connect | Check firewall / Tailscale policy / reverse proxy WebSocket upgrade |
| Chromium / sandbox errors | Set `ORCA_NO_SANDBOX=1`, recreate |
| Build fails downloading AppImage | Check build network or pin `ORCA_APPIMAGE_URL` build arg |
