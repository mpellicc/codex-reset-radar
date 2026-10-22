#!/usr/bin/env bash
# Builds a universal, ad-hoc signed "Codex Reset Radar.app" and a zip for sharing, in dist/.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Codex Reset Radar"
EXECUTABLE="CodexResetRadar"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
BUILD_FLAGS=(-c release --arch arm64 --arch x86_64)

swift build "${BUILD_FLAGS[@]}"
BIN_DIR=$(swift build "${BUILD_FLAGS[@]}" --show-bin-path)

APP="dist/$APP_NAME.app"
rm -rf dist
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$BIN_DIR/$EXECUTABLE" "$APP/Contents/MacOS/$EXECUTABLE"
# Sparkle arrives signed by its developers; ad-hoc signing the app below leaves that signature alone.
ditto "$BIN_DIR/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns Resources/RadarMenuBarTemplate.png Resources/RadarMenuBarTemplate@2x.png \
    "$APP/Contents/Resources/"
cp -R Resources/*.lproj "$APP/Contents/Resources/"

codesign --force --sign - --timestamp=none "$APP"
ditto -c -k --keepParent "$APP" "dist/$EXECUTABLE-$VERSION.zip"

echo "Built $APP"
echo "Share dist/$EXECUTABLE-$VERSION.zip"
