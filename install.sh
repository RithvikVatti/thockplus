#!/bin/bash
set -e

./build.sh

TARGET_DIR="/Applications"
if [ ! -w "/Applications" ]; then
    TARGET_DIR="$HOME/Applications"
    mkdir -p "$TARGET_DIR"
fi

echo "🚀 Installing Snick to $TARGET_DIR..."
# Kill any running instance first
pkill -x Snick 2>/dev/null || true

rm -rf "$TARGET_DIR/Snick.app"
cp -R Snick.app "$TARGET_DIR/"

echo "🎉 Snick installed into $TARGET_DIR/Snick.app"
echo "   Opening Snick now..."
open "$TARGET_DIR/Snick.app"
echo "✨ Remember to grant Accessibility permissions in System Settings -> Privacy & Security -> Accessibility!"
