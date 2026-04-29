# teeny-weeny-cloud
Cloud so small you can't see it.

## Stack

| Service | Role | Port |
|---|---|---|
| Nginx Proxy Manager | Reverse proxy + SSL | 80, 443 (admin: 81) |
| Authentik | SSO / authentication | 9000 |
| Filebrowser | File sharing | 8080 |
| Immich | Photo management | 2283 |
| Jellyfin | Media server | 8096 |
| Joplin Server | Notes sync | 22300 |
| Dockhand | Container update monitoring | 3000 |
| PostgreSQL | Database (Authentik + Joplin) | — |
| PostgreSQL + pgvecto-rs | Database (Immich) | — |
| Redis | Cache (Authentik + Immich) | — |

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

## Setup

### 1. Clone the repo

```bash
git clone <repo-url>
cd teeny-weeny-cloud
```

### 2. Configure environment

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

### 3. Start the stack

```bash
docker compose up -d
```

Services start in dependency order. Postgres initialises first and creates the Authentik and Joplin databases automatically via `init-db.sh`.

### 4. First-login credentials

| Service | URL | Credentials |
|---|---|---|
| Nginx Proxy Manager | http://localhost:81 | `admin@example.com` / `changeme` |
| Authentik | http://localhost:9000 | Setup wizard on first visit |
| Filebrowser | http://localhost:8080 | Auto-generated — check logs: `docker compose logs filebrowser` |
| Immich | http://localhost:2283 | Create account on first visit |
| Jellyfin | http://localhost:8096 | Setup wizard on first visit |
| Joplin Server | http://localhost:22300 | `admin@localhost` / `admin` |
| Dockhand | http://localhost:3000 | Setup on first visit |

Change all default passwords immediately after first login.

### 5. Production: route traffic through Nginx Proxy Manager

For a real deployment with a domain and SSL:

1. Remove direct `ports` from all services except NPM (80, 443, 81) and Authentik (9000, 9443).
2. Open NPM admin at http://your-server:81.
3. Add a Proxy Host for each service using its internal Docker hostname and port:

| App | Forward hostname | Forward port |
|---|---|---|
| Filebrowser | `filebrowser` | `80` |
| Immich | `immich-server` | `2283` |
| Jellyfin | `jellyfin` | `8096` |
| Joplin | `joplin` | `22300` |
| Dockhand | `dockhand` | `3000` |
| Authentik | `authentik-server` | `9000` |

4. Enable SSL (Let's Encrypt) per host in NPM.
5. Add Authentik forward auth to each proxy host for unified login.
6. Close port 81 via firewall after NPM is configured.

## Useful commands

```bash
# Start the stack
docker compose up -d

# Stop the stack
docker compose down

# View logs for a specific service
docker compose logs -f <service-name>

# Restart a single service
docker compose restart <service-name>

# Check container health
docker compose ps
```

## FAQ

**Where is it ???**

It's there, you just can't see it.
