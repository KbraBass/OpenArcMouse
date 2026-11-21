#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

VERSION="${VERSION:-0.1.2}"
BUILD_NUMBER="${BUILD_NUMBER:-3}"

echo "=== Building OpenArcMouse v${VERSION} (Release) ==="
swift build -c release

APP_NAME="OpenArcMouse.app"
BUILD_DIR="$DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=== Creating App Bundle: $APP_DIR ==="
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp ".build/release/OpenArcMouse" "$MACOS_DIR/OpenArcMouse"

# Copy App Icon if present
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Generate Info.plist
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>OpenArcMouse</string>
    <key>CFBundleIdentifier</key>
    <string>com.openarc.mouse</string>
    <key>CFBundleName</key>
    <string>OpenArcMouse</string>
    <key>CFBundleDisplayName</key>
    <string>OpenArcMouse</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSInputMonitoringUsageDescription</key>
    <string>OpenArcMouse requires Input Monitoring permission to communicate directly with your Microsoft Arc Mouse hardware and provide smooth scrolling and gestures.</string>
</dict>
</plist>
EOF

# Code sign with stable designated requirement to preserve Accessibility TCC across rebuilds
echo "=== Signing OpenArcMouse.app ==="
codesign --force --deep --sign - -r='designated => identifier "com.openarc.mouse"' "$APP_DIR"

echo "=== OpenArcMouse.app successfully packaged and signed at: $APP_DIR ==="
