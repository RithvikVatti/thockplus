#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
echo "📦 Packaging Thock+ v$VERSION Release..."

# Build release bundle
./build.sh

mkdir -p releases

ZIP_FILE="releases/Thock+-v${VERSION}-macOS.zip"
DMG_FILE="releases/Thock+-v${VERSION}.dmg"

echo "🗜️  Creating $ZIP_FILE..."
/usr/bin/ditto -c -k --keepParent "Thock+.app" "$ZIP_FILE"

echo "💿 Creating $DMG_FILE..."
rm -rf dmg_temp
mkdir -p dmg_temp
cp -R "Thock+.app" dmg_temp/
ln -s /Applications dmg_temp/Applications
hdiutil create -volname "Thock+" -srcfolder dmg_temp -ov -format UDZO "$DMG_FILE"
rm -rf dmg_temp

echo "🎉 Done! Releases ready in releases/:"
ls -lh releases/
