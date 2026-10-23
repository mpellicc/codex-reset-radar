#!/usr/bin/env bash
# Signs dist/CodexResetRadar.zip for Sparkle and writes dist/appcast.xml offering it.
# Usage: scripts/make-appcast.sh <tag> <release-notes.md>
# The EdDSA private key comes from the SPARKLE_PRIVATE_KEY environment variable, or from the
# login Keychain when it is unset (a local run after generate_keys).
set -euo pipefail
cd "$(dirname "$0")/.."

TAG=$1
NOTES=$2
ZIP=dist/CodexResetRadar.zip
PLIST="dist/Codex Reset Radar.app/Contents/Info.plist"
# Use the tools Xcode downloads under build-app.sh's DerivedData directory.
SPARKLE_BIN=.build/xcode/SourcePackages/artifacts/sparkle/Sparkle/bin
if [ ! -x "$SPARKLE_BIN/sign_update" ]; then
    echo "Sparkle signing tool not found: $SPARKLE_BIN/sign_update. Run scripts/build-app.sh first." >&2
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PLIST")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST")
MINIMUM_SYSTEM=$(/usr/libexec/PlistBuddy -c "Print LSMinimumSystemVersion" "$PLIST")
PUBLIC_KEY=$(/usr/libexec/PlistBuddy -c "Print SUPublicEDKey" "$PLIST")

if [ -n "${SPARKLE_PRIVATE_KEY:-}" ]; then
    KEY_FILE=$(mktemp)
    trap 'rm -f "$KEY_FILE"' EXIT
    printf '%s' "$SPARKLE_PRIVATE_KEY" >"$KEY_FILE"
    SIGNATURE=$("$SPARKLE_BIN/sign_update" --ed-key-file "$KEY_FILE" -p "$ZIP")
elif [ -n "${CI:-}" ]; then
    echo "SPARKLE_PRIVATE_KEY is not set" >&2
    exit 1
else
    SIGNATURE=$("$SPARKLE_BIN/sign_update" --account codex-reset-radar -p "$ZIP")
fi

# sign_update checks against the private key it was given, so a key that doesn't match the app's
# SUPublicEDKey would still pass there. Installed apps would then reject every update.
swift scripts/verify-signature.swift "$PUBLIC_KEY" "$SIGNATURE" "$ZIP"

LENGTH=$(stat -f %z "$ZIP")
URL="https://github.com/mpellicc/codex-reset-radar/releases/download/$TAG/CodexResetRadar.zip"

cat >dist/appcast.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Codex Reset Radar</title>
    <item>
      <title>Version $VERSION</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MINIMUM_SYSTEM</sparkle:minimumSystemVersion>
      <description sparkle:format="markdown"><![CDATA[
$(cat "$NOTES")
]]></description>
      <enclosure url="$URL" length="$LENGTH" type="application/octet-stream" sparkle:edSignature="$SIGNATURE"/>
    </item>
  </channel>
</rss>
EOF

echo "Wrote dist/appcast.xml for $VERSION ($BUILD)"
