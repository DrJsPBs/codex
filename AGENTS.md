# Repository Guidelines

This repository hosts Codex CLI, a monorepo with a Rust workspace (`codex-rs/`) and a thin Node wrapper (`codex-cli/`). Use Rust for core development and pnpm/Prettier for JS/docs hygiene.

## Project Structure & Module Organization
- `codex-rs/`: Rust workspace with crates (e.g., `cli`, `core`, `exec`, `tui`). Entry binary is `codex`.
- `codex-cli/`: Node package exposing `codex` via `bin/codex.js`.
- `docs/`, `scripts/`, `.github/`: Documentation, utility scripts, CI.
- Keep changes within appropriate crates; prefer small, focused modules.

## Build, Test, and Development Commands
- Build (Rust): `cd codex-rs && cargo build`
- Run TUI: `cd codex-rs && cargo run --bin codex -- tui`
- One-off exec: `cd codex-rs && cargo run --bin codex -- exec "your task"`
- Format (Rust): `cd codex-rs && cargo fmt -- --config imports_granularity=Item`
- Lint (Rust): `cd codex-rs && cargo clippy --tests`
- Prettier (repo): `pnpm run format` or `pnpm run format:fix`

## Coding Style & Naming Conventions
- Rust: follow `rustfmt` (workspace config); avoid `unwrap`/`expect` (clippy denies).
- Naming: `snake_case` for functions/vars, `PascalCase` for types/traits, `SCREAMING_SNAKE_CASE` for consts.
- JS/docs: Prettier 3.x; keep files small and focused.

## Testing Guidelines
- Framework: Rust `cargo test` within `codex-rs/`.
- Write unit tests near code (`src/*` and `tests/*`).
- Prefer deterministic tests; avoid network unless mocked.
- Run locally: `cd codex-rs && cargo test` (ensure lints and fmt pass).

## Commit & Pull Request Guidelines
- Use conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, etc.
- PRs include: clear description, rationale, and links to issues; tests for core logic; screenshots for TUI changes when helpful.
- Before pushing: `cargo test && cargo clippy --tests && cargo fmt -- --config imports_granularity=Item` and `pnpm run format`.

## Maintenance & Sync
- Upstream is tracked via local `fork` branch. Keep your `main` up to date with:
  - `./scripts/sync-upstream.sh` (rebase default; see `SYNC.md`).
- Configuration tips: see `codex-rs/config.md` for `RUST_LOG`, paths, and runtime settings.
