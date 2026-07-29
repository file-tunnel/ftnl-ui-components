# ftnl-ui-components

Embeddable File Tunnel pickers for iOS, Android, Flutter, and the web. Every
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

The Flutter and web components are ideal for dynamic loading. Native packages
produce linkable frameworks/AARs; keep their host-facing state protocol stable
so applications can upgrade the transport independently of presentation.

## Validate

```bash
(cd ios && swift package dump-package)
(cd dart && flutter pub get && flutter analyze && flutter test)
(cd web && npm install && npm test)
```

Android CI builds the AAR because local builds require an Android SDK.

MIT licensed.
