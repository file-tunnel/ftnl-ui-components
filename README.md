# ftnl-ui-components

Embeddable File Tunnel pickers for Rust, iOS, Android, Flutter, and the web. Every
component presents the same source choice:

> Files on this device · Files on another device

The host app remains in control. It creates the tunnel through an
[`ftnl-clients`](https://github.com/file-tunnel/ftnl-clients) SDK, supplies the
pairing URI, maps realtime events to progress, imports completed files, and
decides retention. The components never log file metadata or retain
capabilities.

## Packages

| Platform | Package | Integration |
|---|---|---|
| Rust desktop | `rust/` · `ftnl-ui-components` | Host-owned state + optional `egui` renderer |
| iOS/macOS | `ios/` · `FileTunnelUI` | Swift Package dynamic library + SwiftUI |
| Android | `android/` · `dev.filetunnel.ui` | Android AAR + Jetpack Compose |
| Flutter | `dart/` · `ftnl_ui` | Android, iOS, macOS, Windows, Linux, web |
| Web | `web/` · `@file-tunnel/ui` | Lazy-loadable standards-based custom element |

## Shared state contract

Components are renderers for host-owned state:

- `idle`
- `creating`
- `pairing(pairingUri, expiresAt)`
- `transferring(files)`
- `complete`
- `failed(recoverableMessage)`

Hosts should restore a tunnel snapshot after reconnect, treat event sequence
gaps as a signal to refetch, and cancel the backend tunnel when the picker is
dismissed. Pairing URIs are sensitive until redeemed; do not put them in
analytics, crash reports, screenshots, or clipboard history.

The Rust crate is not a second Flutter package: its default build is a
headless, transport-free state contract, and the `egui` feature adds a native
renderer. Like the other native packages, it borrows host-owned pairing state
for one render pass and never stores credentials, performs network requests,
logs file metadata, or writes to the clipboard. This keeps
`ftnl-desktop-app.rs` native without duplicating picker lifecycle semantics.

The Flutter and web components remain ideal for dynamic loading. Native
packages produce Rust libraries, linkable frameworks, or AARs; keep their
host-facing state protocol stable so applications can upgrade the transport
independently of presentation.

## Validate

```bash
nix develop --command agent-check
```

The Nix shell supplies Flutter, Node.js, JDK 21, Gradle 9, and repository
linters. Swift uses the host Xcode toolchain on macOS. Android CI provisions
the licensed platform SDK separately; local Android checks run automatically
when `ANDROID_HOME` is set.

MIT licensed.
