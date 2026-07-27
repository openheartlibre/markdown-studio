#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
APP_PATH="$SCRIPT_DIR/dist/Markdown Studio.app"
RELEASE_DIR="$SCRIPT_DIR/releases"
VERSION="1.1.0"
DMG_PATH="$RELEASE_DIR/Markdown-Studio-$VERSION-macOS-universal.dmg"
STAGING_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

"$SCRIPT_DIR/build_app.command"
mkdir -p "$RELEASE_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/Markdown Studio.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "Markdown Studio" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "Created: $DMG_PATH"
