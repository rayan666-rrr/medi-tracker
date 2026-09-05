#!/usr/bin/env bash
# =============================================================================
#  Medical Tracker BD - "pull the agent's code and run it" (macOS / Linux)
#
#  Usage:
#     ./dev.sh                                  # current branch
#     ./dev.sh arena/01a07170-medi-tracker      # specific branch
#
#  fetch -> checkout -> fast-forward pull -> npm install (if needed) -> vite
#  Never commits, merges, rebases or pushes.
# =============================================================================
set -uo pipefail
cd "$(dirname "$0")"

branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"

echo "[1/4] git fetch origin"
git fetch origin --prune || { echo "!! git fetch failed - check network/login"; exit 1; }

if [ "$branch" != "$(git rev-parse --abbrev-ref HEAD)" ]; then
  echo "[2/4] git checkout $branch"
  git checkout "$branch" || exit 1
else
  echo "[2/4] staying on $branch"
fi

echo "[3/4] git pull --ff-only origin $branch"
if ! git pull --ff-only origin "$branch"; then
  echo
  echo "*** Local edits conflict with the repo, so nothing was changed. ***"
  echo "    see them:  git status"
  echo "    keep them: git stash"
  echo "    discard:   git checkout -- ."
  echo " then run ./dev.sh again."
  exit 1
fi

if [ ! -d node_modules ]; then
  echo "[4/4] first run - npm install (this takes a minute)"
  npm install || exit 1
else
  echo "[4/4] dependencies already installed, skipping"
fi

echo
echo " ============================================"
echo "  Medical Tracker BD  >  http://localhost:3000"
echo "  stop with Ctrl+C"
echo " ============================================"
echo
command -v xdg-open >/dev/null 2>&1 && xdg-open http://localhost:3000
command -v open >/dev/null 2>&1 && open http://localhost:3000
npm run dev
