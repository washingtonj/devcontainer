# orca-devcontainer

Public Docker image that runs [`orca serve`](https://github.com/stablyai/orca) with `asdf` and an SSH server, following the official [Headless Linux Server](https://github.com/stablyai/orca/blob/main/docs/reference/headless-linux-server.md) guide.

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
| `ORCA_PAIRING_ADDRESS` | (required) | Address the Orca client uses to reach this server — not a bind address; wildcards (`*`, `0.0.0.0`, `::`) are rejected |
| `ORCA_PORT` | `6768` | Internal port for `orca serve` |
| `ORCA_JSON` | `0` | Pass `--json` to `serve` |
| `ORCA_MOBILE_PAIRING` | `0` | Enable `--mobile-pairing` |
| `ORCA_NO_SANDBOX` | `0` | Enable only if Chromium reports sandbox errors |
| `SSH_HOST_BIND` | `127.0.0.1` | Host interface the SSH port binds to (compose only) |
| `SSH_HOST_PORT` | `2222` | Host port mapped to the container SSH port (compose only) |
| `SYNCTHING_GUI_ADDRESS` | `0.0.0.0:8384` | Syncthing web UI bind on the host network. Set to `127.0.0.1:8384` to require an SSH tunnel (compose only) |

`ORCA_PORT` is pinned to `6768` by `docker-compose.yml`; change it there or via `docker run -e`.

Build args (only relevant when building the image yourself):

| Build arg | Default | Purpose |
|---|---|---|
| `ORCA_VERSION` | `1.4.205` | Orca .deb package version to download |
| `ORCA_APPIMAGE_URL` | (empty) | Override download URL (default pulls the release .deb; name kept from when the image used AppImage) |

`ORCA_PAIRING_ADDRESS` examples:

| Scenario | Value |
|---|---|
| Same machine | `127.0.0.1` |
| LAN | `192.168.1.50` |
| Tailscale | `100.64.1.20` |
| Reverse proxy (authenticated, see [Network security](#network-security)) | `https://orca.example.com/runtime` |

## Network security

Ports `6768` (`orca serve`) and `22` (sshd) are administrative — **do not expose them on the public internet**. Upstream guidance:

> "Do not publish this port on the public internet; prefer Tailscale / WireGuard / trusted LAN."
> — [Headless Linux Server](https://github.com/stablyai/orca/blob/main/docs/reference/headless-linux-server.md)

Recommended: Tailscale, WireGuard, or bind to `127.0.0.1` / your LAN. A reverse proxy reachable from the internet **is** internet exposure — only proxy it with TLS and authentication (mTLS, SSO or VPN) in front. The proxy must support WebSocket upgrade and route the advertised path; advertise `wss://` (or `https://`) when TLS terminates at the proxy.

Orca runs as unprivileged user `agent` (uid 1000); sshd runs as root for privilege separation.

## Persistence

Mount a volume at `/home/agent`. The volume holds:

- `.asdf/` — installed toolchains (asdf plugins and language versions)
- `.config/orca/` — Orca runtime state, paired-device keys
- `.config/syncthing/` — syncthing config, certs and database (device pairing, folder settings)
- `.ssh/` — SSH host key, generated client key, and `authorized_keys` for the `agent` user
- `workspace/` — accessible at `/workspace` via symlink

Without a volume, all of this is lost on container recreation.

## SSH

### Authentication & keys

Public-key authentication only; password auth, PAM, and root login are disabled.

On first boot the container generates a **client keypair** and stores it in the volume. Pull the private key out and use it to connect:

```bash
docker cp orca:/home/agent/.ssh/id_ed25519_client ~/.ssh/orca_client_key
chmod 600 ~/.ssh/orca_client_key

ssh -p 2222 -i ~/.ssh/orca_client_key agent@<docker-host>
```

To add your own key, append its public half to `/home/agent/.ssh/authorized_keys`:

```bash
docker exec -i orca bash -c \
  'cat >> /home/agent/.ssh/authorized_keys && chmod 600 /home/agent/.ssh/authorized_keys && chown agent:agent /home/agent/.ssh/authorized_keys' \
  < ~/.ssh/your_key.pub
```

The generated key remains authorized when you add your own, so you can keep both or remove it later.

### Port forwarding

Dev servers started by the runtime's agents bind to `127.0.0.1` inside the container, which is not reachable from the host. Forward a port over the SSH connection to open it on the laptop:

```bash
ssh -N -p 2222 -i ~/.ssh/orca_client_key \
  -L 3000:127.0.0.1:3000 -L 5173:127.0.0.1:5173 \
  agent@<host>
```

Then `http://localhost:3000` (or any forwarded port) works on the laptop.

## Toolchains & tools

### asdf

Installed **in the image** (no plugins). Install languages at any time:

```bash
docker exec -u agent -it orca bash -lc \
  'asdf plugin add nodejs && asdf install nodejs latest && asdf set -u nodejs latest'
```

Any [asdf plugin](https://github.com/asdf-vm/asdf-plugins) works (`go`, `deno`, `python`, `rust`, ...). Installations persist in the volume across container recreation.

### syncthing

Optional service that keeps a folder of your choice — e.g. the runtime's agent config under `/home/agent/.config`, or the workspace under `/home/agent/workspace` — in sync with your laptop:

```bash
docker compose up -d syncthing
```

It binds to the host network on ports `22000/tcp+udp` (transfer) and `21027/udp` (discovery). The web UI is served at `http://<docker-host>:8384`:

```bash
open http://<docker-host>:8384
```

> **Authentication is required once exposed.** Syncthing ships with an unauthenticated GUI; any user on the network could reconfigure it. On first open, set a GUI user/password under *Actions → Settings → GUI*, or restrict the bind to `127.0.0.1:8384` and reach it over an SSH tunnel (see [Port forwarding](#port-forwarding)):

```bash
# .env
SYNCTHING_GUI_ADDRESS=127.0.0.1:8384
```

Then add a folder in the GUI and pair with your other devices — syncthing is not pre-configured, and choose folder paths under `/home/agent` so synced data persists in the `orca-home` volume. Device pairing and folder config persist there too.

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
| Build fails downloading Orca | Check build network or pin `ORCA_APPIMAGE_URL` build arg |
