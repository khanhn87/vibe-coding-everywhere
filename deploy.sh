#!/usr/bin/env bash
set -euo pipefail

# GitHub webhook deploy script.
# Reads JSON payload from STDIN and uses webhook headers from env vars:
#   GITHUB_EVENT
#   GITHUB_SIGNATURE_256   (value from X-Hub-Signature-256)
#   WEBHOOK_SECRET         (shared secret)
# Optional env vars:
#   TARGET_BRANCH (default: main)
#   REPO_DIR (default: current directory)
#   REMOTE_NAME (default: origin)
#   LOG_FILE (default: /var/log/vibe-deploy.log)

TARGET_BRANCH="${TARGET_BRANCH:-main}"
REPO_DIR="${REPO_DIR:-$(pwd)}"
REMOTE_NAME="${REMOTE_NAME:-origin}"
LOG_FILE="${LOG_FILE:-/var/log/vibe-deploy.log}"
GITHUB_EVENT="${GITHUB_EVENT:-}"
GITHUB_SIGNATURE_256="${GITHUB_SIGNATURE_256:-}"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-}"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  local msg="$1"
  echo "[$(timestamp)] $msg" | tee -a "$LOG_FILE"
}

fail() {
  local msg="$1"
  log "ERROR: $msg"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing command: $1"
}

verify_signature() {
  local payload_file="$1"

  [[ -n "$WEBHOOK_SECRET" ]] || fail "WEBHOOK_SECRET is required"
  [[ -n "$GITHUB_SIGNATURE_256" ]] || fail "GITHUB_SIGNATURE_256 is required"

  local expected
  expected="sha256=$(openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" "$payload_file" | awk '{print $2}')"

  if [[ "$expected" != "$GITHUB_SIGNATURE_256" ]]; then
    fail "Signature mismatch"
  fi
}

extract_ref() {
  local payload_file="$1"
  jq -r '.ref // empty' "$payload_file"
}

main() {
  require_cmd git
  require_cmd jq
  require_cmd openssl

  mkdir -p "$(dirname "$LOG_FILE")"

  local payload_file
  payload_file="$(mktemp)"
  trap 'rm -f "$payload_file"' EXIT

  cat > "$payload_file"

  log "Received webhook event=${GITHUB_EVENT:-unknown}"

  [[ "$GITHUB_EVENT" == "push" ]] || {
    log "Skip: only push events are deployed"
    exit 0
  }

  verify_signature "$payload_file"

  local ref
  ref="$(extract_ref "$payload_file")"
  local expected_ref="refs/heads/$TARGET_BRANCH"

  [[ "$ref" == "$expected_ref" ]] || {
    log "Skip: ref '$ref' does not match '$expected_ref'"
    exit 0
  }

  [[ -d "$REPO_DIR/.git" ]] || fail "REPO_DIR is not a git repository: $REPO_DIR"

  cd "$REPO_DIR"

  log "Deploy start: repo=$REPO_DIR branch=$TARGET_BRANCH"

  git fetch "$REMOTE_NAME" "$TARGET_BRANCH" >> "$LOG_FILE" 2>&1
  git reset --hard "$REMOTE_NAME/$TARGET_BRANCH" >> "$LOG_FILE" 2>&1

  if [[ -f package-lock.json ]]; then
    if command -v npm >/dev/null 2>&1; then
      log "Detected package-lock.json, running npm ci"
      npm ci >> "$LOG_FILE" 2>&1
    else
      log "package-lock.json present but npm not found"
    fi
  fi

  log "Deploy success"
}

main "$@"
