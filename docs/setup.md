# Setup

## Prerequisites

- Docker + Docker Compose
- NAS mounted on the host before starting the stack. Add to `/etc/fstab` for a persistent NFS mount:

```
nas-ip:/export/path  /mnt/nas  nfs  defaults,_netdev  0  0
```

Then mount:

```bash
sudo mount -a
```

## 1. Clone the repo

```bash
git clone <repo-url>
cd teeny-weeny-cloud
```

## 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` and fill in all values. At minimum:

- Generate a secret key for Authentik:
  ```bash
  openssl rand -hex 32
  ```
  Paste the output as `AUTHENTIK_SECRET_KEY`.

- Set `DATA_PATH` to a local directory where app configs and databases will be stored (e.g. `./data`).
- Set `NAS_PATH` to the mount point of your NAS (e.g. `/mnt/nas`). Must be mounted before starting.
- Set `JOPLIN_BASE_URL` to the URL Joplin clients will use (e.g. `http://localhost:22300` for local testing).
- Replace all `changeme` passwords with strong values.

## 3. Start the stack

```bash
docker compose up -d
```

Services start in dependency order. Postgres initialises first and creates the Authentik and Joplin databases automatically via `init-db.sh`.

## 4. First-login credentials

| Service | URL | Credentials |
|---|---|---|
| Nginx Proxy Manager | http://localhost:81 | `admin@example.com` / `changeme` |
| Authentik | http://localhost:9000 | Setup wizard on first visit |
| Filebrowser | http://localhost:8080 | Auto-generated — check logs: `docker compose logs filebrowser` |
| Immich | http://localhost:2283 | Create account on first visit |
| Jellyfin | http://localhost:8096 | Setup wizard on first visit |
| Joplin Server | http://localhost:22300 | `admin@localhost` / `admin` |
| Dockhand | http://localhost:3000 | Setup on first visit |

!!! warning
    Change all default passwords immediately after first login.
