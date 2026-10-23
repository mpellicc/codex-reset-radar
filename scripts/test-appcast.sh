#!/usr/bin/env bash
# Exercises release signing with Xcode's Sparkle tools, without production keys or the login Keychain.
# Run scripts/build-app.sh first to download the pinned tools.
set -euo pipefail
cd "$(dirname "$0")/.."

SPARKLE_BIN="$PWD/.build/xcode/SourcePackages/artifacts/sparkle/Sparkle/bin"
if [ ! -x "$SPARKLE_BIN/sign_update" ]; then
    echo "Run scripts/build-app.sh before testing the appcast" >&2
    exit 1
fi

TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

swift - "$TEST_ROOT" <<'SWIFT'
import CryptoKit
import Foundation

let directory = URL(fileURLWithPath: CommandLine.arguments[1])
for index in 1...2 {
    let key = Curve25519.Signing.PrivateKey()
    try key.rawRepresentation.base64EncodedString().write(
        to: directory.appendingPathComponent("private-\(index)"), atomically: true, encoding: .utf8)
    try key.publicKey.rawRepresentation.base64EncodedString().write(
        to: directory.appendingPathComponent("public-\(index)"), atomically: true, encoding: .utf8)
}
SWIFT

PRIVATE_KEY=$(cat "$TEST_ROOT/private-1")
PUBLIC_KEY=$(cat "$TEST_ROOT/public-1")
OTHER_PRIVATE_KEY=$(cat "$TEST_ROOT/private-2")

new_case() {
    CASE_DIR="$TEST_ROOT/$1"
    mkdir -p "$CASE_DIR/scripts" "$CASE_DIR/.build/xcode/SourcePackages/artifacts/sparkle/Sparkle"
    cp scripts/make-appcast.sh scripts/verify-signature.swift "$CASE_DIR/scripts/"
    ln -s "$SPARKLE_BIN" "$CASE_DIR/.build/xcode/SourcePackages/artifacts/sparkle/Sparkle/bin"
    # Deliberately omit SwiftPM's .build/artifacts tree: CI's swift build must not hide a release bug.
    python3 - "$CASE_DIR" "$PUBLIC_KEY" <<'PY'
import pathlib
import plistlib
import sys
import zipfile

root = pathlib.Path(sys.argv[1])
contents = root / "dist/Codex Reset Radar.app/Contents"
contents.mkdir(parents=True)
with (contents / "Info.plist").open("wb") as stream:
    plistlib.dump({
        "CFBundleShortVersionString": "1.2.3",
        "CFBundleVersion": "42",
        "LSMinimumSystemVersion": "15.0",
        "SUPublicEDKey": sys.argv[2],
    }, stream)
with zipfile.ZipFile(root / "dist/CodexResetRadar.zip", "w") as archive:
    archive.write(contents / "Info.plist", "Codex Reset Radar.app/Contents/Info.plist")
(root / "notes.md").write_text("# Release notes\n\nSigning smoke test.\n")
PY
}

run_appcast() {
    CI=true SPARKLE_PRIVATE_KEY="$1" bash "$CASE_DIR/scripts/make-appcast.sh" v1.2.3 "$CASE_DIR/notes.md"
}

expect_failure() {
    if run_appcast "$1" >"$CASE_DIR/output.log" 2>&1; then
        echo "Expected appcast generation to fail: $CASE_DIR" >&2
        exit 1
    fi
    if ! grep -Fq "$2" "$CASE_DIR/output.log"; then
        cat "$CASE_DIR/output.log" >&2
        exit 1
    fi
    test ! -e "$CASE_DIR/dist/appcast.xml"
}

new_case success
run_appcast "$PRIVATE_KEY"
SIGNATURE=$(python3 - "$CASE_DIR" <<'PY'
import pathlib
import sys
import xml.etree.ElementTree as ET

root = pathlib.Path(sys.argv[1])
sparkle = "{http://www.andymatuschak.org/xml-namespaces/sparkle}"
item = ET.parse(root / "dist/appcast.xml").find("channel/item")
assert item is not None, "Missing appcast item"
assert item.findtext("title") == "Version 1.2.3"
assert item.findtext(sparkle + "version") == "42"
assert item.findtext(sparkle + "shortVersionString") == "1.2.3"
assert item.findtext(sparkle + "minimumSystemVersion") == "15.0"
description = item.find("description")
assert description.attrib[sparkle + "format"] == "markdown"
assert description.text.strip() == (root / "notes.md").read_text().strip()
enclosure = item.find("enclosure")
assert enclosure.attrib["url"] == (
    "https://github.com/mpellicc/codex-reset-radar/releases/download/v1.2.3/CodexResetRadar.zip"
)
assert enclosure.attrib["length"] == str((root / "dist/CodexResetRadar.zip").stat().st_size)
assert enclosure.attrib["type"] == "application/octet-stream"
print(enclosure.attrib[sparkle + "edSignature"])
PY
)
swift scripts/verify-signature.swift "$PUBLIC_KEY" "$SIGNATURE" "$CASE_DIR/dist/CodexResetRadar.zip"
echo "PASS: Xcode-only signing, appcast metadata and archive signature"

new_case wrong-key
expect_failure "$OTHER_PRIVATE_KEY" "The signature doesn't match SUPublicEDKey"
echo "PASS: a mismatched signing key is rejected before writing the appcast"

new_case missing-key
expect_failure "" "SPARKLE_PRIVATE_KEY is not set"
echo "PASS: CI requires an explicit signing key"

new_case missing-signer
rm "$CASE_DIR/.build/xcode/SourcePackages/artifacts/sparkle/Sparkle/bin"
# Even a populated legacy cache must not conceal a missing Xcode build artifact.
mkdir -p "$CASE_DIR/.build/artifacts/sparkle/Sparkle"
ln -s "$SPARKLE_BIN" "$CASE_DIR/.build/artifacts/sparkle/Sparkle/bin"
expect_failure "$PRIVATE_KEY" "Sparkle signing tool not found: .build/xcode/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update. Run scripts/build-app.sh first."
echo "PASS: a missing Xcode signer has an actionable diagnostic"
