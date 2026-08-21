#!/bin/bash
# Build an unsigned (ad-hoc signed) release DMG for a GitHub release.
#
#   Scripts/release.sh [version]
#
# "Unsigned" means ad-hoc, not signature-free: arm64 refuses to execute a
# binary with no signature at all, so `-` is the minimum that runs anywhere.
# It does not get past Gatekeeper — see the README's install section.
#
# Ad-hoc cannot carry the App Group entitlement either, so UserDefaults falls
# back to .standard in a downloaded build. That is harmless here because only
# the app reads those keys; the widget reads volumes directly and shares
# nothing through the group.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-$(date +%Y.%m.%d)}"
BUILD="build/release"
STAGE="$BUILD/dmg"
DMG="build/DiskUsage-$VERSION.dmg"

rm -rf "$BUILD" "$DMG"
mkdir -p "$STAGE"

echo "==> building $VERSION"
xcodebuild \
    -project DiskUsageWidget.xcodeproj \
    -scheme DiskUsage \
    -configuration Release \
    -derivedDataPath "$BUILD/dd" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="" \
    PROVISIONING_PROFILE_SPECIFIER="" \
    CODE_SIGN_ENTITLEMENTS="$PWD/Scripts/release.entitlements" \
    MARKETING_VERSION="$VERSION" \
    build | grep -E "error:|\*\* BUILD" || true

APP="$BUILD/dd/Build/Products/Release/Disk Usage.app"
[ -d "$APP" ] || { echo "build produced no app at $APP" >&2; exit 1; }

echo "==> staging"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "==> verifying the signature is at least ad-hoc"
codesign --verify --deep --strict "$STAGE/Disk Usage.app"

echo "==> checking the widget survived: NSExtension must still be there"
/usr/libexec/PlistBuddy -c "Print :NSExtension:NSExtensionPointIdentifier" \
    "$STAGE/Disk Usage.app/Contents/PlugIns/DiskUsageWidgetExtension.appex/Contents/Info.plist" \
    >/dev/null

echo "==> packaging"
hdiutil create -volname "Disk Usage" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null

echo
echo "$DMG"
echo "  $(du -h "$DMG" | cut -f1)"
echo
echo "Publish with:"
echo "  gh release create v$VERSION \"$DMG\" --notes-file docs/release-notes.md"
