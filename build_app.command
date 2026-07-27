#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR"

swift build -c release --arch arm64
swift build -c release --arch x86_64

APP_DIR="$SCRIPT_DIR/dist/Markdown Studio.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
xcrun lipo -create \
    ".build/arm64-apple-macosx/release/MarkdownStudio" \
    ".build/x86_64-apple-macosx/release/MarkdownStudio" \
    -output "$MACOS_DIR/MarkdownStudio"
chmod +x "$MACOS_DIR/MarkdownStudio"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

codesign --force --deep --sign - "$APP_DIR"

echo "已生成：$APP_DIR"
