# teeny-weeny-cloud

> **THIS PROJECT IS UNDER DEVELOPMENT — USE AT YOUR OWN RISK**

Cloud so small you have to squint to see it.

An **almost** 1-click deployment for a minimal yet sufficient personal cloud to host files, media, and notes on a personal home server. Designed for a 2-machine setup: a NAS holding data, and a small server running the apps.

**Minimum server spec:** 2 cores CPU / 4 GB RAM / 32 GB SSD.

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

## FAQ

### Why?

To give that old laptop a second life — and to stop feeding your photos, notes, and files to corporations that store them forever, sell the metadata, train models on your memories, won't let you leave, and insidiously force you into a dystopian techno-servitude from which there will be no escape.

### AI?

Yes, to generate configuration, debug, format and proofread the readme. Testing done by hand.
