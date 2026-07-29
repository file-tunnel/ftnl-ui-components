# shellcheck shell=bash
set -euo pipefail

(
  cd web
  npm ci
  npm test
)

(
  cd dart
  flutter pub get
  dart format --output=none --set-exit-if-changed .
  flutter analyze
  flutter test
)

if [[ "$(uname -s)" == "Darwin" ]] &&
  env -u DEVELOPER_DIR -u SDKROOT /usr/bin/xcrun --find swift >/dev/null 2>&1; then
  (cd ios && env -u DEVELOPER_DIR -u SDKROOT /usr/bin/swift test)
else
  echo "Skipping Swift tests: they require macOS with Xcode."
fi

if [[ -n "${ANDROID_HOME:-}" ]]; then
  (cd android && gradle :library:lint :library:testDebugUnitTest :library:assembleRelease)
else
  echo "Skipping Android build: enter nix develop after provisioning ANDROID_HOME."
fi
