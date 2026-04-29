# Going further

## Security

- **Close direct ports** — remove all `ports` from compose except NPM (80, 443). Restrict port 81 (NPM admin) to local network only via firewall.
- **Firewall** — allow only ports 80 and 443 from the outside: `ufw allow 80,443/tcp && ufw enable`.
- **Enforce 2FA in Authentik** — edit the default authentication flow to require TOTP. One policy covers all apps behind forward auth.
- **Rotate default passwords** — change all credentials set during first login (NPM, Joplin, Filebrowser) once the stack is running.
- **Crowdsec** — install on the host (not in Docker). Automatically bans IPs with suspicious patterns across all services.

## Backups

- **Database dumps** — schedule a `pg_dump` for both Postgres instances. Store dumps on the NAS, not on the server.
- **NAS redundancy** — RAID is not a backup. Follow the 3-2-1 rule: 3 copies, 2 different media, 1 offsite (e.g. Backblaze B2 via Rclone).
- **Test restores** — a backup you have never restored is not a backup.

## Reliability

- **UPS** — a power cut mid-write corrupts Postgres. A small UPS with a graceful shutdown script protects data integrity.
- **Automatic updates** — schedule a weekly `docker compose pull && docker compose up -d`. Dockhand notifies of available updates but does not apply them.
- **Uptime Kuma** — lightweight self-hosted status page, easy to add to the compose. Alerts when a service goes down.

## Functionality

- **Tailscale** — access the stack remotely without exposing anything to the internet. Removes the need for a public domain if you only need personal access.
- **Dynamic DNS** — if your home IP changes, services become unreachable. Use a DDNS provider (Cloudflare, DuckDNS) with a small cron job to keep DNS updated.
- **Hardware transcoding in Jellyfin** — pass the iGPU through to the container (`devices: /dev/dri`) for near-zero CPU transcoding.
- **Immich external library** — point Immich at existing NAS photo folders to index them without re-uploading.
