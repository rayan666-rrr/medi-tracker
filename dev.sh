#!/usr/bin/env bash
# =============================================================================
#  Medical Tracker BD - "pull the agent's code and run it" (macOS / Linux)
#
#  Usage:
#     ./dev.sh arena/01a07170-medi-tracker   # first run only
#     ./dev.sh                               # after that
#
#  fetch -> checkout/create branch -> fast-forward pull -> npm install (if
#  needed) -> vite. Handles single-branch clones (remote.origin.fetch mapped to
#  main only), which is why a plain "git checkout <branch>" often fails with
#  "pathspec did not match" on AI-Studio-made clones.
#  Never commits, merges, rebases or pushes.
# =============================================================================
set -uo pipefail
cd "$(dirname "$0")"

branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"
echo
echo " branch: $branch"
echo

echo "[1/4] git fetch origin $branch"
git fetch origin "+refs/heads/$branch:refs/remotes/origin/$branch" \
  || { echo "!! git fetch failed - check network and 'gh auth status'"; exit 1; }
git fetch origin --prune 2>/dev/null

echo "[2/4] checkout"
if git rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
  if [ "$branch" != "$(git rev-parse --abbrev-ref HEAD)" ]; then
    git checkout "$branch" || exit 1
  else
    echo "  already on $branch"
  fi
else
  git checkout -b "$branch" "origin/$branch" || exit 1
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
