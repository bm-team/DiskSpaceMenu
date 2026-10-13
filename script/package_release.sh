#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$ROOT_DIR/VERSION")"
APP_NAME="DiskSpaceMenu"
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/diskspace-release.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT

cd "$ROOT_DIR"
for arch in arm64 x86_64; do
  swift build -c release --triple "$arch-apple-macosx14.0" --scratch-path ".build-release-$arch"
done

APP="$STAGING/$APP_NAME.app"
mkdir -p "$APP/Contents/MacOS"
xcrun lipo -create \
  ".build-release-arm64/arm64-apple-macosx/release/$APP_NAME" \
  ".build-release-x86_64/x86_64-apple-macosx/release/$APP_NAME" \
  -output "$APP/Contents/MacOS/$APP_NAME"
chmod +x "$APP/Contents/MacOS/$APP_NAME"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$APP_NAME</string>
<key>CFBundleIdentifier</key><string>com.badmonkey.DiskSpaceMenu</string>
<key>CFBundleName</key><string>Место на дисках</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>2</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST

codesign --force --sign - --identifier com.badmonkey.DiskSpaceMenu "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
xcrun lipo -archs "$APP/Contents/MacOS/$APP_NAME"

ARCHIVE="$ROOT_DIR/dist/release/$APP_NAME-v$VERSION-macOS-universal.zip"
mkdir -p "$(dirname "$ARCHIVE")"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
shasum -a 256 "$ARCHIVE"
echo "$ARCHIVE"
