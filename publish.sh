#!/bin/bash
set -e

BLOG_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$BLOG_DIR/../0x4ngk4n.github.io"
MSG="${1:-update blog}"

echo "==> Building site..."
cd "$BLOG_DIR"
hugo build --cleanDestinationDir

echo "==> Committing to 0x4ngk4n.github.io..."
cd "$SITE_DIR"
git add -A
git commit -m "$MSG"
git push origin main

echo "==> Committing source to blog..."
cd "$BLOG_DIR"
git add -A
git commit -m "$MSG"
git push origin main

echo "==> Done! Site is live at https://0x4ngk4n.github.io"
