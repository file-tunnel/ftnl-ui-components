# shellcheck shell=bash
set -euo pipefail

# Keep the Nix toolchain's artifacts separate from a developer's global Rust
# toolchain; rustc metadata is intentionally not cross-version compatible.
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$PWD/.cache/nix-agent/cargo-target}"
export RUSTUP_TOOLCHAIN="${RUSTUP_TOOLCHAIN:-stable}"

python3 scripts/generate-picker-machine.py --check
tlc -workers 1 -metadir .cache/nix-agent/tlc formal/PickerStateMachine.tla \
  -config formal/PickerStateMachine.cfg

(
  cd langs/rust
  cargo fmt --check
  cargo clippy --locked --all-targets --all-features -- -D warnings
  cargo test --locked --all-targets --all-features
)

(
  cd langs/typescript
  npm ci
  npm test
)

(
  cd langs/dart
  flutter pub get
  dart format --output=none --set-exit-if-changed .
  flutter analyze
  flutter test
)

if [[ "$(uname -s)" == "Darwin" ]] &&
  env -u DEVELOPER_DIR -u SDKROOT /usr/bin/xcrun --find swift >/dev/null 2>&1; then
  (cd langs/swift && env -u DEVELOPER_DIR -u SDKROOT /usr/bin/swift test)
else
  echo "Skipping Swift tests: they require macOS with Xcode."
fi

if [[ -n "${ANDROID_HOME:-}" ]]; then
  (cd langs/kotlin && gradle :library:lint :library:testDebugUnitTest :library:assembleRelease)
else
  echo "Skipping Android build: enter nix develop after provisioning ANDROID_HOME."
fi
