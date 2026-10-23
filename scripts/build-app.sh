#!/usr/bin/env bash
# Builds a universal, ad-hoc signed "Codex Reset Radar.app" and a zip for sharing, in dist/.
# The app is built by Xcode from project.yml (XcodeGen), so the bundle, App Intents metadata, Siri phrase
# assets and the SDK version recorded in the binary come out the way Xcode makes them. See docs/adr/0003.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Codex Reset Radar"
EXECUTABLE="CodexResetRadar"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
PROJECT="$EXECUTABLE.xcodeproj"
DERIVED=.build/xcode

xcodegen generate --quiet
# Package.resolved is the one pin for Sparkle; give the generated project the same one and hold Xcode to it.
mkdir -p "$PROJECT/project.xcworkspace/xcshareddata/swiftpm"
cp Package.resolved "$PROJECT/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
xcodebuild build -quiet \
    -project "$PROJECT" -scheme "$EXECUTABLE" -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$DERIVED" \
    -onlyUsePackageVersionsFromResolvedFile

APP="dist/$APP_NAME.app"
rm -rf dist
mkdir -p dist
ditto "$DERIVED/Build/Products/Release/$EXECUTABLE.app" "$APP"

# macOS picks the app's look from the SDK version recorded in the binary: anything below 26 gets the
# pre-Liquid Glass windows and controls. Xcode records it right; fail loudly if that ever changes.
SDK_VERSION=$(xcrun --sdk macosx --show-sdk-version)
if vtool -show-build "$APP/Contents/MacOS/$EXECUTABLE" | awk '$1 == "sdk"' | grep -qv " $SDK_VERSION\$"; then
    echo "error: $EXECUTABLE doesn't record SDK $SDK_VERSION" >&2
    vtool -show-build "$APP/Contents/MacOS/$EXECUTABLE" >&2
    exit 1
fi
test "$(lipo -archs "$APP/Contents/MacOS/$EXECUTABLE")" = "x86_64 arm64"
# Shortcuts and Siri find the app's App Intents through these.
test -f "$APP/Contents/Resources/Metadata.appintents/extract.actionsdata"
codesign --verify --strict "$APP"

ditto -c -k --keepParent "$APP" "dist/$EXECUTABLE-$VERSION.zip"

echo "Built $APP"
echo "Share dist/$EXECUTABLE-$VERSION.zip"
