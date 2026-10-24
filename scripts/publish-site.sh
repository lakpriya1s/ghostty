#!/bin/sh
# Publishes site/ (the KinTerm web page) to the gh-pages branch, which
# GitHub Pages serves at https://lakpriya.com/kinterm/ (the owner's
# custom domain).
#
#   scripts/publish-site.sh
#
# gh-pages also holds the update feed (appcast.xml, written by the release
# workflow). This only adds or replaces the site's own files and never
# touches the feed.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PAGES=$(mktemp -d)
trap 'git -C "$ROOT" worktree remove --force "$PAGES" 2>/dev/null || true' EXIT

cd "$ROOT"
if git fetch origin gh-pages 2>/dev/null; then
  git worktree add --force "$PAGES" origin/gh-pages
  git -C "$PAGES" checkout -B gh-pages
else
  git worktree add --force --orphan -b gh-pages "$PAGES"
fi

cp site/* "$PAGES"/
touch "$PAGES/.nojekyll"
git -C "$PAGES" add -A .
if git -C "$PAGES" diff --cached --quiet; then
  echo "Site is already up to date."
  exit 0
fi
git -C "$PAGES" commit -m "site: $(git rev-parse --short HEAD)"
git -C "$PAGES" push origin gh-pages
echo "Published. Live in a minute at https://lakpriya.com/kinterm/"
