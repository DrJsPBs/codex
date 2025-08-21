#!/usr/bin/env bash
set -Eeuo pipefail

# Sync local branches with upstream and push to origin.
#
# Default behavior:
# - Ensure local `fork` mirrors `upstream/main` exactly
# - Update `main` from `fork` using rebase (custom commits stay on top)
# - Push `main` to `origin`
#
# You can change behavior via flags or env vars:
#   --strategy [rebase|merge]   (STRATEGY, default: rebase)
#   --no-push / --push          (PUSH=0/1, default: 1)
#   --origin <name>             (ORIGIN, default: origin)
#   --upstream <name>           (UPSTREAM, default: upstream)
#   --main <name>               (MAIN_BRANCH, default: main)
#   --fork <name>               (FORK_BRANCH, default: fork)
#   --dry-run                   (DRY_RUN=1)
#
# Examples:
#   scripts/sync-upstream.sh
#   scripts/sync-upstream.sh --strategy merge
#   scripts/sync-upstream.sh --no-push --dry-run

usage() {
  cat <<'USAGE'
Sync your custom main with upstream via the tracking fork branch.

Options:
  --strategy [rebase|merge]  How to integrate upstream into main (default: rebase)
  --no-push | --push         Disable/enable pushing main to origin after update (default: push)
  --origin <name>            Name of your remote (default: origin)
  --upstream <name>          Name of the upstream remote (default: upstream)
  --main <name>              Your custom branch (default: main)
  --fork <name>              Local mirror of upstream main (default: fork)
  --dry-run                  Print commands without executing
  -h, --help                 Show this help

Environment overrides:
  STRATEGY, PUSH, ORIGIN, UPSTREAM, MAIN_BRANCH, FORK_BRANCH, DRY_RUN
USAGE
}

msg() { echo "[sync] $*"; }
run() {
  echo "+ $*";
  if [[ "${DRY_RUN:-0}" -eq 0 ]]; then "$@"; fi
}

# Defaults
STRATEGY=${STRATEGY:-rebase}
PUSH=${PUSH:-1}
ORIGIN=${ORIGIN:-origin}
UPSTREAM=${UPSTREAM:-upstream}
MAIN_BRANCH=${MAIN_BRANCH:-main}
FORK_BRANCH=${FORK_BRANCH:-fork}
DRY_RUN=${DRY_RUN:-0}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strategy)
      STRATEGY=${2:-}; shift 2 ;;
    --no-push)
      PUSH=0; shift ;;
    --push)
      PUSH=1; shift ;;
    --origin)
      ORIGIN=${2:-}; shift 2 ;;
    --upstream)
      UPSTREAM=${2:-}; shift 2 ;;
    --main)
      MAIN_BRANCH=${2:-}; shift 2 ;;
    --fork)
      FORK_BRANCH=${2:-}; shift 2 ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage; exit 2 ;;
  esac
done

if [[ "$STRATEGY" != "rebase" && "$STRATEGY" != "merge" ]]; then
  echo "Invalid --strategy: $STRATEGY (use 'rebase' or 'merge')" >&2
  exit 2
fi

# Ensure we are inside a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repository. Run from within the repo root." >&2
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Ensure clean working tree
git update-index -q --refresh
if ! git diff-index --quiet HEAD --; then
  echo "Working tree has local changes. Please commit/stash before syncing." >&2
  exit 1
fi

# Verify remotes exist
if ! git remote get-url "$UPSTREAM" >/dev/null 2>&1; then
  echo "Remote '$UPSTREAM' not found." >&2; exit 1
fi
if ! git remote get-url "$ORIGIN" >/dev/null 2>&1; then
  echo "Remote '$ORIGIN' not found." >&2; exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
msg "Starting on branch: $CURRENT_BRANCH"

cleanup() {
  # If a rebase is in progress, do not attempt to switch branches
  if [[ -d "$(git rev-parse --git-path rebase-merge)" || -d "$(git rev-parse --git-path rebase-apply)" ]]; then
    msg "Rebase in progress; not switching back to $CURRENT_BRANCH."
    return
  fi
  if [[ $(git rev-parse --abbrev-ref HEAD) != "$CURRENT_BRANCH" ]]; then
    run git checkout -q "$CURRENT_BRANCH" || true
  fi
}
trap cleanup EXIT

msg "Fetching remotes ($UPSTREAM, $ORIGIN)"
run git fetch "$UPSTREAM" --prune
run git fetch "$ORIGIN" --prune

# Ensure or update fork branch to exactly mirror upstream main
if git show-ref --quiet "refs/heads/$FORK_BRANCH"; then
  msg "Updating '$FORK_BRANCH' to $UPSTREAM/$MAIN_BRANCH"
  run git checkout "$FORK_BRANCH"
else
  msg "Creating '$FORK_BRANCH' from $UPSTREAM/$MAIN_BRANCH"
  run git checkout -b "$FORK_BRANCH" "$UPSTREAM/$MAIN_BRANCH"
fi
run git reset --hard "$UPSTREAM/$MAIN_BRANCH"

# Update main from fork
msg "Updating '$MAIN_BRANCH' from '$FORK_BRANCH' via $STRATEGY"
run git checkout "$MAIN_BRANCH"

if [[ "$STRATEGY" == "rebase" ]]; then
  run git rebase "$FORK_BRANCH"
else
  # Prefer fast-forward when possible, otherwise create a merge commit without opening editor
  if git merge-base --is-ancestor HEAD "$FORK_BRANCH"; then
    run git merge --ff-only "$FORK_BRANCH"
  else
    run git merge --no-ff "$FORK_BRANCH" --no-edit
  fi
fi

# Push main to origin
if [[ "$PUSH" -eq 1 ]]; then
  msg "Pushing '$MAIN_BRANCH' to $ORIGIN"
  run git push "$ORIGIN" "$MAIN_BRANCH"
else
  msg "Skipping push (use --push to enable)"
fi

msg "Sync complete."
