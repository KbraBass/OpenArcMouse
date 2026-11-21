#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

VERSION="${VERSION:-0.1.3}"
BUILD_DIR="$DIR/build"
APP_PATH="$BUILD_DIR/OpenArcMouse.app"
OUTPUT_DMG="$BUILD_DIR/OpenArcMouse-v${VERSION}.dmg"

echo "=== Packaging OpenArcMouse v${VERSION} into DMG ==="

# 1. Build app bundle if missing
if [ ! -d "$APP_PATH" ]; then
    echo "App bundle not found at $APP_PATH. Building..."
    VERSION="$VERSION" ./scripts/build-app.sh
fi

# 2. Ensure DMG background image exists
if [ ! -f "Resources/dmg-background.png" ]; then
    echo "Generating DMG background image..."
    swift scripts/generate-dmg-background.swift
fi

# 3. Ensure create-dmg is available
if ! command -v create-dmg &> /dev/null; then
    echo "create-dmg not found in PATH."
    if command -v brew &> /dev/null; then
        echo "Installing create-dmg via Homebrew..."
        brew install create-dmg
    else
        echo "Downloading create-dmg script..."
        TMP_CREATE_DMG="/tmp/create-dmg"
        curl -sSL "https://raw.githubusercontent.com/create-dmg/create-dmg/master/create-dmg" -o "$TMP_CREATE_DMG"
        chmod +x "$TMP_CREATE_DMG"
        export PATH="/tmp:$PATH"
    fi
fi

# 4. Prepare clean staging directory
STAGING_DIR="$BUILD_DIR/dmg-staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
if [ -f "Resources/PLEASE READ - First Launch.txt" ]; then
    cp "Resources/PLEASE READ - First Launch.txt" "$STAGING_DIR/"
fi

# 5. Remove previous DMG if it exists
rm -f "$OUTPUT_DMG"
rm -f "$BUILD_DIR/OpenArcMouse.dmg"

echo "Creating styled DMG at $OUTPUT_DMG..."
create-dmg \
  --volname "OpenArcMouse" \
  --volicon "Resources/AppIcon.icns" \
  --background "Resources/dmg-background.png" \
  --window-pos 200 120 \
  --window-size 660 620 \
  --icon-size 80 \
  --text-size 12 \
  --icon "OpenArcMouse.app" 170 145 \
  --hide-extension "OpenArcMouse.app" \
  --app-drop-link 490 145 \
  --icon "PLEASE READ - First Launch.txt" 330 265 \
  --hide-extension "PLEASE READ - First Launch.txt" \
  --no-internet-enable \
  "$OUTPUT_DMG" \
  "$STAGING_DIR"

rm -rf "$STAGING_DIR"

# Also create a non-versioned copy for convenience
cp "$OUTPUT_DMG" "$BUILD_DIR/OpenArcMouse.dmg"

echo "=== DMG package successfully created at: $OUTPUT_DMG ==="
