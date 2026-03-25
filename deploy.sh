#!/usr/bin/env bash
set -Eeuo pipefail

BRANCH="${BRANCH:-main}"
SOURCE_DIR="${SOURCE_DIR:-$(pwd)}"

cd "$SOURCE_DIR"
git fetch --prune origin "$BRANCH"
git reset --hard "origin/$BRANCH"
git clean -fd
  
git pull origin
	