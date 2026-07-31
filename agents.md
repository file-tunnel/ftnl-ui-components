# File Tunnel UI component agent instructions

These instructions apply to this repository and every directory beneath it.

## Repository role

- This repository owns File Tunnel presentation components for Swift,
  Android/Compose, Flutter, and the web.
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
