# Troubleshooting

## A service won't start / keeps restarting

Check what the container is actually complaining about:

```bash
docker compose logs -f <service-name>
```

## Check overall stack health

Shows each container's status and whether healthchecks are passing:

```bash
docker compose ps
```

## A service is unhealthy but logs look fine

The healthcheck may be timing out before the service is ready. Restart it and give it more time:

```bash
docker compose restart <service-name>
```

## Postgres fails to create Authentik / Joplin databases

`init-db.sh` only runs on a **fresh, empty** data directory. If Postgres was started once before the script was in place, the data dir already exists and the script is skipped. Fix:

```bash
docker compose down
rm -rf <DATA_PATH>/postgres
docker compose up -d
```

## Changes to `.env` are not picked up

Environment variables are injected at container creation time, not at runtime. Recreate affected containers:

```bash
docker compose up -d --force-recreate <service-name>
```

## Authentik forward auth redirects to a blank page or 404

The outpost is not configured. In Authentik go to `Outposts` → edit the embedded outpost → make sure all protected applications are listed under `Selected Applications`.

## Direct port access works but NPM proxy returns 502

The app container is not on the `proxy` network, or the forward hostname is wrong. Check that:

- the app has `proxy` in its `networks` in `compose.yml`
- NPM proxy host uses the Docker service name as hostname (e.g. `filebrowser`, not `localhost`)

## Full reset (wipe all data and start fresh)

!!! danger
    This deletes all app data, databases, and config. There is no undo.

```bash
docker compose down -v
rm -rf <DATA_PATH>
docker compose up -d
```
