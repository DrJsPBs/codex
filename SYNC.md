# Syncing Upstream Changes

This repo is configured with two primary branches and two remotes:

- `main`: your custom branch, tracks `origin/main` (your GitHub fork)
- `fork`: a clean mirror of `upstream/main` (the source repository)
- `origin`: your GitHub fork remote
- `upstream`: the original source remote (`openai/codex`)

Use the helper script to keep `main` up to date with upstream while preserving your local customizations.

## Quick Start

- Rebase (default): keeps your custom commits on top of upstream changes

```
./scripts/sync-upstream.sh
```

- Merge strategy: creates merge commits instead of rebasing

```
./scripts/sync-upstream.sh --strategy merge
```

## What the Script Does

1. Fetches from `upstream` and `origin`.
2. Updates local branch `fork` to exactly match `upstream/main`.
3. Updates `main` from `fork` using your chosen strategy (default: `rebase`).
4. Pushes `main` to `origin` (unless `--no-push` is used).

`fork` is intended to remain a pristine mirror of upstream. Do not land custom commits on `fork`.

## Options

- `--strategy [rebase|merge]`: how to integrate upstream into `main` (default: `rebase`).
- `--no-push` / `--push`: disable/enable pushing `main` to `origin` (default: push).
- `--origin <name>`: remote name for your fork (default: `origin`).
- `--upstream <name>`: remote name for upstream (default: `upstream`).
- `--main <name>`: your custom branch name (default: `main`).
- `--fork <name>`: local mirror branch for upstream (default: `fork`).
- `--dry-run`: print commands without executing.

Environment variables can override the same values: `STRATEGY`, `PUSH`, `ORIGIN`, `UPSTREAM`, `MAIN_BRANCH`, `FORK_BRANCH`, `DRY_RUN`.

## Examples

- Preview actions without making changes:

```
./scripts/sync-upstream.sh --no-push --dry-run
```

- Use merge commits and push:

```
./scripts/sync-upstream.sh --strategy merge --push
```

- Custom remote/branch names:

```
ORIGIN=myfork UPSTREAM=upstream MAIN_BRANCH=main FORK_BRANCH=fork \
  ./scripts/sync-upstream.sh
```

## Notes

- The script requires a clean working tree (commit or stash first).
- On rebase conflicts, resolve them and run `git rebase --continue`.
- The script attempts to fast-forward merges when possible; otherwise it creates a merge commit when `--strategy merge` is used.
- By design, the script does not push `fork`—only `main` to your `origin`.
