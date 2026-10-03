#!/bin/sh
# One time only: hands ports 80/443 from landing-page's own Caddy to this one.
# Run on the server as `deploy`, from /srv/proxy, after the first deploy has
# cloned the repo. irmahs.dev is unreachable only between the stop and the up.
set -eu
cd "$(dirname "$0")/.."

docker network create proxy 2>/dev/null || true

# Put the running landing page on the shared network under the alias the
# Caddyfile uses, so it answers as soon as the new Caddy starts.
web=$(docker compose --project-directory /srv/landing-page ps -q web)
docker network connect --alias landing-page proxy "$web" 2>/dev/null || true

# Create this project's volumes and copy the existing certificates in, so
# nothing has to be issued again.
docker compose create caddy
for v in caddy_data caddy_config; do
	docker run --rm \
		-v "landing-page_$v:/from:ro" -v "proxy_$v:/to" \
		alpine cp -a /from/. /to/
done

old=$(docker compose --project-directory /srv/landing-page ps -q caddy)
docker stop "$old"
docker rm "$old"
docker compose up -d

echo "Done. Now merge landing-page's chore/shared-proxy branch."
