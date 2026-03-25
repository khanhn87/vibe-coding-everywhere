# Vibe Everywhere Setup Site

Simple static website to document your Telegram-driven remote coding flow with Codex CLI, CCPoke, VPS, and GitHub.

## Run locally

```bash
# from this folder
python -m http.server 8080
```

Open `http://localhost:8080`.

## Customize

- Edit setup text and sections in `index.html`
- Replace sample commands in blocks `cmd-1` to `cmd-5` in `index.html`
- Update style/theme in `styles.css`
- Copy button behavior is in `script.js`

## Webhook Deploy Script

Use `deploy.sh` on your VPS to force-sync on GitHub `push` webhook.
It runs `git reset --hard` to discard all local changes before updating to remote state.

Required webhook header-to-env mapping in your receiver:

- `X-GitHub-Event` -> `GITHUB_EVENT`
- `X-Hub-Signature-256` -> `GITHUB_SIGNATURE_256`

Required env vars:

- `WEBHOOK_SECRET` (same as GitHub webhook secret)
- `REPO_DIR` (absolute repo path on VPS)

Optional env vars:

- `TARGET_BRANCH` (default `main`)
- `REMOTE_NAME` (default `origin`)
- `LOG_FILE` (default `/var/log/vibe-deploy.log`)

Example call from receiver:

```bash
export WEBHOOK_SECRET='your-secret'
export GITHUB_EVENT="$header_x_github_event"
export GITHUB_SIGNATURE_256="$header_x_hub_signature_256"
export REPO_DIR='/opt/vibe-everywhere'
cat payload.json | ./deploy.sh
```