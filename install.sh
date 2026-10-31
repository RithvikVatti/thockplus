#!/bin/bash
set -e

./build.sh

TARGET_DIR="/Applications"
if [ ! -w "/Applications" ]; then
    TARGET_DIR="$HOME/Applications"
    mkdir -p "$TARGET_DIR"
fi

echo "🚀 Installing Thock+ to $TARGET_DIR..."
# Kill any running instance first
pkill -x ThockPlus 2>/dev/null || true
pkill -x Snick 2>/dev/null || true

rm -rf "$TARGET_DIR/Thock+.app"
cp -R "Thock+.app" "$TARGET_DIR/"

echo "🎉 Thock+ installed into $TARGET_DIR/Thock+.app"
echo "   Opening Thock+ now..."
open "$TARGET_DIR/Thock+.app"
echo "✨ Remember to grant Accessibility permissions in System Settings -> Privacy & Security -> Accessibility!"
