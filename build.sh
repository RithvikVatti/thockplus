#!/bin/bash
set -e

echo "🔨 Building Thock+ (Release)..."
swift build -c release

APP_NAME="Thock+.app"
CONTENTS="$APP_NAME/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "📦 Creating $APP_NAME bundle..."
rm -rf "$APP_NAME"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES/Sounds/Keyboard"
mkdir -p "$RESOURCES/Sounds/Mouse"

# Copy binary
cp .build/release/ThockPlus "$MACOS/ThockPlus"
chmod +x "$MACOS/ThockPlus"

# Copy Info.plist
cp Resources/Info.plist "$CONTENTS/Info.plist"

# Copy Icon
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$RESOURCES/AppIcon.icns"
fi

# Copy Menu Bar icons
cp Resources/MenuBarIcon*.png "$RESOURCES/" 2>/dev/null || true

# Copy Sounds
cp Resources/Sounds/*.wav "$RESOURCES/Sounds/" 2>/dev/null || true
cp Resources/Sounds/Keyboard/* "$RESOURCES/Sounds/Keyboard/" 2>/dev/null || true
cp Resources/Sounds/Mouse/* "$RESOURCES/Sounds/Mouse/" 2>/dev/null || true

# Copy SPM resource bundle if present
if [ -d .build/release/ThockPlus_ThockPlus.bundle ]; then
    cp -R .build/release/ThockPlus_ThockPlus.bundle "$RESOURCES/"
fi

# Ad-hoc code signing for local execution on macOS
echo "✍️  Ad-hoc codesigning $APP_NAME..."
codesign --force --deep --sign - "$APP_NAME"

echo "✅ Successfully built $APP_NAME!"
echo "   Run './$APP_NAME/Contents/MacOS/ThockPlus' or 'open \"$APP_NAME\"' to launch."
