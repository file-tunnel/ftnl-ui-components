# File Tunnel UI component agent instructions

These instructions apply to this repository and every directory beneath it.

## Repository role

- This repository owns File Tunnel presentation components for Rust/egui,
  Swift, Android/Compose, Flutter, and the web.
- Components render host-owned state; they do not own transport credentials,
  backend lifecycle, or durable capability storage.
- Keep the source-choice and picker-state behavior aligned across platforms
  while preserving platform-idiomatic APIs and accessibility.
- Never log or retain pairing URIs, capabilities, filenames, file metadata, or
  user content. Avoid analytics, screenshots, and clipboard behavior that
  could expose a pairing fragment.
- Keep progress bounded and require hosts to reconcile event gaps from a
  snapshot.

## Validation

- Run `nix develop --command agent-check` before completing a change.
- Test the affected platform while iterating and all available platform suites
  before completing a cross-platform change.
- Never commit platform build output, package caches, credentials, or
  machine-specific SDK state.

## Git workflow

- Keep changes focused and reviewable.
- Pull and merge remote work before pushing; avoid git rebase in favor of git merge.
- Never discard unrelated or uncommitted user work.

## Repository-local Git worktrees

- Create or use a Git worktree only when the human operator explicitly authorizes it for the current task. Concurrency or a dirty checkout is not permission by itself.
- Put every authorized worktree at `<repository-root>/tmp/worktrees/<name>`; from the repository root, use `./tmp/worktrees/<name>`. Never place worktrees beside repositories or organization directories.
- Keep `tmp`, `temp`, `tmp/worktrees`, and `temp/worktrees` ignored in the repository-root `.gitignore`. Do not commit files from those directories.
- Relocate or remove a worktree only when the operator explicitly requests it. Before removal, preserve and publish intended changes, verify its commit is represented on the target branch, and confirm there are no tracked, untracked, ignored-sensitive, or in-use files that must survive. Remove it with `git worktree remove <path>` without `--force`; never delete a worktree directory with `rm`.
