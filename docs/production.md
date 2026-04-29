# Production

Local port mappings are for testing only. In production, all traffic must go through Nginx Proxy Manager — direct port access bypasses SSL and Authentik entirely.

## 1. Remove direct ports

In `compose.yml`, remove all `ports` entries except:

- NPM: `80`, `443`, `81`
- Authentik: `9000`, `9443`

## 2. Configure Nginx Proxy Manager

Open NPM admin at `http://your-server:81` and add a Proxy Host for each service using its internal Docker hostname and port:

| App | Forward hostname | Forward port |
|---|---|---|
| Filebrowser | `filebrowser` | `80` |
| Immich | `immich-server` | `2283` |
| Jellyfin | `jellyfin` | `8096` |
| Joplin | `joplin` | `22300` |
| Dockhand | `dockhand` | `3000` |
| Authentik | `authentik-server` | `9000` |

## 3. Enable SSL

Enable Let's Encrypt per proxy host in NPM. Requires a public domain pointing to your server.

## 4. Enable Authentik forward auth

Add Authentik forward auth to each proxy host. See [Authentication](authentication.md) for the full setup procedure.

## 5. Lock down NPM admin

Close port 81 via firewall once NPM is fully configured — or restrict it to your local network only:

```bash
ufw deny 81
ufw allow from 192.168.1.0/24 to any port 81
```
