#!/bin/bash
# Post-build: publish the freshly built app to /Applications so the desktop
# widget gallery picks up the new code. Widgets only load from a registered
# location, never from DerivedData.
set -euo pipefail

SRC="${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}"
DEST="/Applications/${WRAPPER_NAME}"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

[ -d "$SRC" ] || { echo "warning: $SRC not found, skipping install"; exit 0; }

# Not fatal if /Applications is not writable - the build itself still succeeded.
if ! rm -rf "$DEST" 2>/dev/null || ! cp -R "$SRC" /Applications/ 2>/dev/null; then
    echo "warning: could not install to /Applications; desktop widget will be stale"
    exit 0
fi

"$LSREGISTER" -f "$DEST" || true
echo "installed $DEST"
