# teeny-weeny-cloud

> THIS PROJECT IS UNDER DEVELOPMENT, USE AT YOUR OWN RISKS!!

Cloud so small you have to squint to see it.

An **almost** 1-click deployment for a minimal -yet sufficient- personnal cloud to host files, media, and notes on a personal home server. This is designed for a 2-machines setup: a NAS holding data, and a small server (minimum 2 cores CPU / 4 GB RAM / 32 GB SSD) for apps.

TO DO:
- 1 device (no NAS) setup
- Docker Compose service template to easily extend setup (with dedicated "How to extend" doc)
- Doc website
- test
- Isolated local-only version with no auth for portable ephemeral cloud

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

## Authentication

Authentik provides unified login for all apps. It works in two modes depending on what each app supports:

- **Forward auth** — NPM intercepts every request and asks Authentik if the user is logged in. The app itself is unaware. Used for Filebrowser, Dockhand, Joplin.
- **Native OIDC** — the app redirects to Authentik for login and receives a token back. Real SSO: log in once, all OIDC apps recognize you. Used for Immich and Jellyfin.

> Authentication only works once apps are routed through NPM with real domain names. Direct port access bypasses Authentik entirely.

### Step 1 — Authentik initial setup

Go to `http://your-server:9000/if/flow/initial-setup/` and create your admin account.

### Step 2 — Forward auth (Filebrowser, Dockhand, Joplin)

Repeat for each app:

**In Authentik** (`Applications → Providers → Create`):
1. Type: `Proxy Provider` — Mode: `Forward auth (single application)`
2. External URL: the public URL of the app (e.g. `https://files.yourdomain.com`)
3. Create an `Application` and link it to the provider
4. Go to `Outposts` → edit the default embedded outpost → add the application

**In NPM**, on the proxy host for that app → `Advanced` tab → paste:

```nginx
auth_request /outpost.goauthentik.io/auth/nginx;
error_page 401 = @goauthentik_proxy_signin;
auth_request_set $authentik_username $upstream_http_x_authentik_username;
auth_request_set $authentik_groups $upstream_http_x_authentik_groups;

location /outpost.goauthentik.io {
    proxy_pass http://authentik-server:9000/outpost.goauthentik.io;
    proxy_set_header Host $host;
    proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
}

location @goauthentik_proxy_signin {
    internal;
    return 302 /outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
}
```

### Step 3 — OIDC for Immich

**In Authentik** (`Applications → Providers → Create`):
1. Type: `OAuth2/OpenID Provider` — Client type: `Confidential`
2. Redirect URI: `https://immich.yourdomain.com/auth/login`
3. Note the `Client ID` and `Client Secret`
4. Create an `Application` linked to the provider

**In Immich** (`Administration → OAuth`):
- Issuer URL: `https://authentik.yourdomain.com/application/o/immich/`
- Client ID + Secret: from Authentik
- Scope: `openid profile email`

### Step 4 — OIDC for Jellyfin

1. In Jellyfin, install the `SSO Authentication` plugin from the plugin catalog → restart
2. In Authentik, create an `OAuth2/OpenID Provider` for Jellyfin (same as above, with Jellyfin's redirect URI)
3. In the Jellyfin SSO plugin settings, fill in Authentik's issuer URL, client ID, and secret

## Troubleshooting

### A service won't start / keeps restarting

Check what the container is actually complaining about:

```bash
docker compose logs -f <service-name>
```

### Check overall stack health

Shows each container's status and whether healthchecks are passing:

```bash
docker compose ps
```

### A service is unhealthy but logs look fine

The healthcheck may be timing out before the service is ready. Restart it and give it more time:

```bash
docker compose restart <service-name>
```

### Postgres fails to create Authentik / Joplin databases

`init-db.sh` only runs on a **fresh, empty** data directory. If Postgres was started once before the script was in place, the data dir already exists and the script is skipped. Fix:

```bash
docker compose down
rm -rf <DATA_PATH>/postgres
docker compose up -d
```

### Changes to `.env` are not picked up

Environment variables are injected at container creation time, not at runtime. Recreate affected containers:

```bash
docker compose up -d --force-recreate <service-name>
```

### Authentik forward auth redirects to a blank page or 404

The outpost is not configured. In Authentik go to `Outposts` → edit the embedded outpost → make sure all protected applications are listed under `Selected Applications`.

### Direct port access works but NPM proxy returns 502

The app container is not on the `proxy` network, or the forward hostname is wrong. Check that:
- the app has `proxy` in its `networks` in `compose.yml`
- NPM proxy host uses the Docker service name as hostname (e.g. `filebrowser`, not `localhost`)

### Full reset (wipe all data and start fresh)

> **Warning:** this deletes all app data, databases, and config.

```bash
docker compose down -v
rm -rf <DATA_PATH>
docker compose up -d
```

## Going further

### Security

- **Close direct ports** — remove all `ports` from compose except NPM (80, 443). Restrict port 81 (NPM admin) to local network only via firewall.
- **Firewall** — allow only ports 80 and 443 from the outside: `ufw allow 80,443/tcp && ufw enable`.
- **Enforce 2FA in Authentik** — edit the default authentication flow to require TOTP. One policy covers all apps behind forward auth.
- **Rotate default passwords** — change all credentials set during first login (NPM, Joplin, Filebrowser) once the stack is running.
- **Crowdsec** — install on the host (not in Docker). Automatically bans IPs with suspicious patterns across all services.

### Backups

- **Database dumps** — schedule a `pg_dump` for both Postgres instances. Store dumps on the NAS, not on the server.
- **NAS redundancy** — RAID is not a backup. Follow the 3-2-1 rule: 3 copies, 2 different media, 1 offsite (e.g. Backblaze B2 via Rclone).
- **Test restores** — a backup you have never restored is not a backup.

### Reliability

- **UPS** — a power cut mid-write corrupts Postgres. A small UPS with a graceful shutdown script protects data integrity.
- **Automatic updates** — schedule a weekly `docker compose pull && docker compose up -d`. Dockhand notifies of available updates but does not apply them.
- **Uptime Kuma** — lightweight self-hosted status page, easy to add to the compose. Alerts when a service goes down.

### Functionality

- **Tailscale** — access the stack remotely without exposing anything to the internet. Removes the need for a public domain if you only need personal access.
- **Dynamic DNS** — if your home IP changes, services become unreachable. Use a DDNS provider (Cloudflare, DuckDNS) with a small cron job to keep DNS updated.
- **Hardware transcoding in Jellyfin** — pass the iGPU through to the container (`devices: /dev/dri`) for near-zero CPU transcoding.
- **Immich external library** — point Immich at existing NAS photo folders to index them without re-uploading.

## FAQ

### Why?

To reuse old hardware, quickly deploy local-only servers 