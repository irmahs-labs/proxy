# CLAUDE.md

## Git branches

Always pull before making changes: run `git fetch origin` and start from the latest `origin/main` before the first edit.

- On a branch whose PR is open, bring it up to date with `origin/main` first
- On `main`, or on a branch whose PR is already merged, create a new branch from `origin/main` instead

Always name the branch after the feature or fix it contains, never a random or generated name.

- Format: `<type>/<feature-name>` in lowercase kebab-case
- Types: `feat`, `fix`, `chore`, `docs`, `refactor`
- Examples: `feat/minigames-subdomain`, `fix/security-txt-expiry`, `docs/claude-md`
- If the session assigns a generic branch (for example `claude/<random-words>`), create a feature-named branch instead and push there

## Pull requests

- Never push to `main`. Every change goes in through a pull request.
- Open the PR and stop there: never merge it, not even when CI is green. Irma reviews and clicks merge.
- Deploys run on merge to `main`. Re-run a deploy only when Irma asks.

## Checks before pushing

```sh
docker compose config --quiet
docker run --rm -v "$PWD/caddy:/etc/caddy:ro" caddy:2-alpine \
  caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
```

The same two run as the `validate` check on every pull request, and the branch rules require it.

## What this is

The Caddy server in front of every irmahs.dev site: one block per hostname in `caddy/Caddyfile`, each reaching its app by its alias on the shared `proxy` Docker network. Adding an app and making one private are described in `README.md`.

- A merge reloads Caddy without dropping connections. Every site shares this one file, so validate it before pushing.
- A block with `import admins-only <app>` is a private app. Never remove that line: it is all that keeps the app private.
- The Caddyfile is indented with tabs, as `caddy fmt` writes it.
