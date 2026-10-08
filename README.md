# proxy

The Caddy server in front of every site on the irmahs.dev server. It holds ports 80 and 443, gets the HTTPS certificates, and routes each hostname to its app over the shared `proxy` Docker network. Every site also gets the same `/.well-known/security.txt`.

```
visitor ──HTTPS──▶ Caddy (this repo) ──proxy network──▶ landing-page:3000      irmahs.dev
                                                    └─▶ sleepy-spinner         pantry-spinner.irmahs.dev
```

## Layout

```
caddy/Caddyfile        one block per hostname
caddy/security.txt     served on every site; renew Expires before 2027-10-03
compose.yaml           Caddy only, on the external `proxy` network
scripts/cutover.sh     one time: takes 80/443 over from landing-page's Caddy
.github/workflows/     validate on every PR, deploy on main
```

## Adding an app on a subdomain

1. Cloudflare: `A` and `AAAA` records for the subdomain → the server, **DNS only**.
2. In the app's `compose.yaml`, join the network under an alias and publish no ports:
   ```yaml
   services:
     app:
       networks:
         proxy:
           aliases: [my-app]
   networks:
     proxy:
       external: true
   ```
3. Here, add a block to `caddy/Caddyfile` and merge:
   ```
   my-app.irmahs.dev {
   	import common
   	handle {
   		reverse_proxy my-app:3000
   	}
   }
   ```

The deploy reloads Caddy, which does not drop connections. No other site restarts.

## Secrets

Same three as the other repos (Settings → Secrets and variables → Actions, or once at organization level): `DEPLOY_SSH_KEY`, `DEPLOY_KNOWN_HOSTS`, `DEPLOY_HOST`.

## First setup (one time)

1. As the admin user: `sudo mkdir /srv/proxy && sudo chown deploy:deploy /srv/proxy`.
2. Push to `main`. The deploy clones the repo, then stops on purpose because landing-page's Caddy still holds the ports.
3. As `deploy`: `sh /srv/proxy/scripts/cutover.sh`. It copies the existing certificates, stops the old Caddy and starts this one. irmahs.dev is down for a few seconds.
4. Merge landing-page's `chore/shared-proxy` branch straight after, so its next deploy no longer brings its own Caddy back.
