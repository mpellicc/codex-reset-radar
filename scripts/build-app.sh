#!/usr/bin/env bash
# Builds a universal, ad-hoc signed "Codex Reset Radar.app" and a zip for sharing, in dist/.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Codex Reset Radar"
EXECUTABLE="CodexResetRadar"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
# Swift Build (not the native build system) emits the constant values the App Intents step below reads.
BUILD_FLAGS=(-c release --arch arm64 --arch x86_64 --build-system swiftbuild)

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

# Shortcuts and Siri find the app's App Intents through Contents/Resources/Metadata.appintents.
# Xcode extracts it at build time; SwiftPM doesn't, so run the same tool on what the compiler left behind.
INTENTS_OBJECTS=".build/out/Intermediates.noindex/$EXECUTABLE.build/Release/$EXECUTABLE-p.build/Objects-normal/arm64"
MIN_MACOS=$(/usr/libexec/PlistBuddy -c "Print LSMinimumSystemVersion" Resources/Info.plist)
echo "$PWD/$INTENTS_OBJECTS/$EXECUTABLE-primary.swiftconstvalues" > "$INTENTS_OBJECTS/ConstValuesList"
xcrun appintentsmetadataprocessor --quiet-warnings \
    --output "$APP/Contents/Resources" \
    --toolchain-dir "$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain" \
    --module-name "$EXECUTABLE" \
    --sdk-root "$(xcrun --sdk macosx --show-sdk-path)" \
    --xcode-version "$(xcodebuild -version | awk '/Build version/ { print $3 }')" \
    --platform-family macOS \
    --deployment-target "$MIN_MACOS" \
    --target-triple "arm64-apple-macos$MIN_MACOS" \
    --source-file-list "$INTENTS_OBJECTS/$EXECUTABLE.SwiftFileList" \
    --swift-const-vals-list "$INTENTS_OBJECTS/ConstValuesList"
test -f "$APP/Contents/Resources/Metadata.appintents/extract.actionsdata"
# Siri matches the App Shortcut phrases (it.lproj/AppShortcuts.strings for Italian) through these trained assets.
INTENTS_TMP=$(mktemp -d)
xcrun appintentsnltrainingprocessor --archive-ssu-assets \
    --extracted-metadata-path "$APP/Contents/Resources/Metadata.appintents" \
    --infoplist-path "$APP/Contents/Info.plist" \
    --temp-dir-path "$INTENTS_TMP" \
    --bundle-id "$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" Resources/Info.plist)" \
    --product-path "$APP/Contents/Resources"
rm -rf "$INTENTS_TMP"

codesign --force --sign - --timestamp=none "$APP"
ditto -c -k --keepParent "$APP" "dist/$EXECUTABLE-$VERSION.zip"

echo "Built $APP"
echo "Share dist/$EXECUTABLE-$VERSION.zip"
