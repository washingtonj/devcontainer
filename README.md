# Devserver in Docker

Headless **Remote Orca Server** (`orca serve`) packaged for Docker, following the official [headless Linux server](https://github.com/stablyai/orca/blob/main/docs/reference/headless-linux-server.md) guide.

Your laptop stays the UI; agents, terminals, vitest, and git run inside the container with **CPU/RAM limits** so the host does not freeze.

## Quick start

```bash
cp .env.example .env
# Edit ORCA_PAIRING_ADDRESS (see below)

mkdir -p home/ssh home/workspace
docker compose up -d --build

# Watch startup until you see the pairing URL
docker compose logs -f devserver
```

Look for something like:

```text
Orca server ready
Bound endpoint: ws://0.0.0.0:6768
Advertised endpoint: ws://127.0.0.1:6768
Pairing URL: orca://pair?code=...
```

On your **laptop** Orca app:

1. **Settings → Remote Orca Servers → Add Server**
2. Paste the **Pairing URL**
3. Connect and work as usual — runtime lives in the container

## SSH access

The container also runs `sshd` on host port `2222` by default. SSH host keys, `sshd_config` and `authorized_keys` are stored in `./home/ssh` and survive container recreation.

Add a public key on the host before connecting:

```bash
cat ~/.ssh/id_ed25519.pub >> home/ssh/authorized_keys
chmod 600 home/ssh/authorized_keys

ssh -p 2222 agent@<docker-host>
```

Only public-key authentication is enabled and root login is disabled. Set `SSH_HOST_BIND` and `SSH_HOST_PORT` in `.env` to change the bind address or host port. Protect port `2222` with the host firewall; do not expose it publicly without network access controls.

## `ORCA_PAIRING_ADDRESS`

This is the address the **client** must be able to open. It is **not** the Docker bind address.

| Scenario | `ORCA_PAIRING_ADDRESS` | `ORCA_HOST_BIND` |
|----------|------------------------|------------------|
| Client on same machine | `127.0.0.1` | `127.0.0.1` (default) |
| Client on LAN | Host LAN IP, e.g. `192.168.1.50` | `0.0.0.0` |
| Tailscale | Host Tailscale IP `100.x.y.z` | `0.0.0.0` (or Tailscale-only firewall) |

Do **not** use `0.0.0.0`, `*` or `::` as pairing address (invalid to advertise).  
Do **not** publish this port on the public internet; prefer Tailscale / WireGuard / trusted LAN.

## Resource limits

Defaults in `docker-compose.yml`:

- **RAM:** 3 GB (`mem_limit`)
- **CPU:** 3 cores (`cpus`)
- **shm:** 1 GB (helps Chromium)

Edit and recreate:

```bash
docker compose up -d --force-recreate
```

## Auth (git + agents)

Same rule as any Remote Orca Server: install and log in **inside** the server environment.

```bash
# Shell as the agent user in the container
docker compose exec devserver bash

# Examples (once CLIs are installed):
# gh auth login
# orca account add --agent codex
# orca account add --agent claude
```

The complete agent home is bind-mounted from `${HOST_HOME:-./home}` to `/home/agent`. SSH state is stored in `home/ssh`, and workspace data in `home/workspace`; `/workspace` inside the container points to that directory.

Install agent CLIs however you prefer (npm global, official installers, etc.) inside that shell; they need to live on the server PATH/home.

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| Chromium / sandbox errors | Set `ORCA_NO_SANDBOX=1` in `.env`, recreate |
| No pairing URL | Check logs; ensure `ORCA_PAIRING_ADDRESS` is a real reachable host (not `0.0.0.0`) |
| Client cannot connect | Same address/port as advertised; firewall; use Tailscale |
| Build fails downloading AppImage | Network on build machine; or pin `ORCA_APPIMAGE_URL` build-arg |
| Host still feels slow | Lower parallel agents; limit vitest workers; tighten `mem_limit` / `cpus` |

## Useful commands

```bash
docker compose logs -f          # pairing URL + diagnostics
docker compose exec devserver bash
docker compose restart
docker compose down             # stop (keeps the host-mounted home)
rm -rf ./home                       # explicitly wipe local home state
```

## Notes

- Image extracts the AppImage at **build** time (`--appimage-extract`) because Docker usually has no FUSE.
- Runs `sshd` as root for privilege separation, then Orca as user `agent` (uid 1000).
- The host-mounted `home/` directory owns agent, SSH and workspace state; keep it backed up.
- Official docs still treat **bare metal + systemd** or **desktop app + Tailscale** as the primary paths; this compose is a practical sandbox with hard resource caps.
- Updating Orca: rebuild the image (`docker compose build --no-cache && docker compose up -d`) to pull the latest AppImage.
- On a fresh host home, ASDF/Node is initialized from the image snapshot on first startup.
