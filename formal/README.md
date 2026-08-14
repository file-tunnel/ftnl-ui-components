# Picker lifecycle formal model

`picker-machine.json` is the reviewed source of truth for the host-controlled
picker lifecycle. `scripts/generate-picker-machine.py` deterministically emits
the TLA+ specification and transition APIs for Rust, Dart/Flutter, TypeScript,
Kotlin, and Swift.

The model separates control facts from sensitive values. Its states record only
whether a host session is required and whether one asynchronous effect is in
flight. Pairing URIs, capabilities, file metadata, paths, and user content are
never model inputs or trace values.

TLC explores both every allowed transition and every rejected state/event pair.
The checked invariants are:

- the state and event vocabulary is closed;
- session authority is present exactly in states that require it;
- at most one effect is represented as in flight;
- the complete state retains neither session authority nor an in-flight effect;
- rejected events stutter instead of changing control state.

This is an exhaustive proof for the finite control abstraction, not a proof of
the network, operating system, renderer, or arbitrary host code. Platform tests
therefore replay every state/event pair through the generated runtime APIs, and
host applications must keep their own effect correlation and data invariants.

Run the complete check with:

```sh
nix develop --command agent-check
```
