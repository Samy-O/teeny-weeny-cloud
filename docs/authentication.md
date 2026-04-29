# Authentication

Authentik provides unified login for all apps. It works in two modes depending on what each app supports:

- **Forward auth** — NPM intercepts every request and asks Authentik if the user is logged in. The app itself is unaware. Used for Filebrowser, Dockhand, Joplin.
- **Native OIDC** — the app redirects to Authentik for login and receives a token back. Real SSO: log in once, all OIDC apps recognize you. Used for Immich and Jellyfin.

!!! warning
    Authentication only works once apps are routed through NPM with real domain names. Direct port access bypasses Authentik entirely.

## Step 1 — Initial setup

Go to `http://your-server:9000/if/flow/initial-setup/` and create your admin account.

## Step 2 — Forward auth (Filebrowser, Dockhand, Joplin)

Repeat for each app.

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

## Step 3 — OIDC for Immich

**In Authentik** (`Applications → Providers → Create`):

1. Type: `OAuth2/OpenID Provider` — Client type: `Confidential`
2. Redirect URI: `https://immich.yourdomain.com/auth/login`
3. Note the `Client ID` and `Client Secret`
4. Create an `Application` linked to the provider

**In Immich** (`Administration → OAuth`):

- Issuer URL: `https://authentik.yourdomain.com/application/o/immich/`
- Client ID + Secret: from Authentik
- Scope: `openid profile email`

## Step 4 — OIDC for Jellyfin

1. In Jellyfin, install the `SSO Authentication` plugin from the plugin catalog → restart
2. In Authentik, create an `OAuth2/OpenID Provider` for Jellyfin (same as above, with Jellyfin's redirect URI)
3. In the Jellyfin SSO plugin settings, fill in Authentik's issuer URL, client ID, and secret
