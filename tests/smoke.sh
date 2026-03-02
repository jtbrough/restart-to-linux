#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cleanup() {
  rm -rf "$ROOT_DIR/tests/tmp" "$ROOT_DIR/tests/tmp-apps"
}
trap cleanup EXIT HUP INT TERM

"$ROOT_DIR/src/bin/restart-to-linux" --help >/dev/null
"$ROOT_DIR/src/bin/restart-to-linux" --version >/dev/null
"$ROOT_DIR/src/bin/restart-to-linux" --check >/dev/null
"$ROOT_DIR/src/bin/restart-to-linux" --debug --check >/dev/null
app_dir="$ROOT_DIR/tests/tmp-apps"
mkdir -p "$app_dir"
RESTART_TO_LINUX_APP_INSTALL_DIR="$app_dir" "$ROOT_DIR/src/bin/restart-to-linux" --install-app >/dev/null
[ -d "$app_dir/Restart to Linux.app" ]
plutil -p "$app_dir/Restart to Linux.app/Contents/Info.plist" | grep -F '"CFBundleIconFile" => "applet"' >/dev/null
plutil -p "$app_dir/Restart to Linux.app/Contents/Info.plist" | grep -F '"LSRequiresNativeExecution" => true' >/dev/null
[ -f "$app_dir/Restart to Linux.app/Contents/Resources/restart-to-linux.applescript" ]
[ -f "$app_dir/Restart to Linux.app/Contents/Resources/applet.icns" ]
[ -f "$app_dir/Restart to Linux.app/Contents/MacOS/restart-to-linux-launcher" ]
cmp -s "$ROOT_DIR/packaging/macos/AsahiLinux.icns" "$app_dir/Restart to Linux.app/Contents/Resources/applet.icns"
RESTART_TO_LINUX_APP_INSTALL_DIR="$app_dir" "$ROOT_DIR/src/bin/restart-to-linux" --uninstall-app >/dev/null
[ ! -e "$app_dir/Restart to Linux.app" ]
RESTART_TO_LINUX_APFS_LIST_FILE="$ROOT_DIR/tests/fixtures/apfs-list.txt" \
  "$ROOT_DIR/src/bin/restart-to-linux" --list | grep -Fx "/Volumes/Arch Linux" >/dev/null
if RESTART_TO_LINUX_APFS_LIST_FILE="$ROOT_DIR/tests/fixtures/apfs-list-ambiguous.txt" \
  "$ROOT_DIR/src/bin/restart-to-linux" --dry-run >/dev/null 2>&1; then
  echo "expected ambiguous fixture to fail" >&2
  exit 1
fi
mkdir -p "$ROOT_DIR/tests/tmp/Arch Linux"
mkdir -p "$ROOT_DIR/tests/tmp/Fedora Asahi Remix"
cat >"$ROOT_DIR/tests/tmp/apfs-list-ambiguous.txt" <<EOF
APFS Containers (2 found)
|
+-- Container disk2
|   +-> Volume disk2s2
|   |   APFS Volume Disk (Role):   disk2s2 (System)
|   |   Mount Point:               $ROOT_DIR/tests/tmp/Arch Linux
|
+-- Container disk5
    +-> Volume disk5s2
    |   APFS Volume Disk (Role):   disk5s2 (System)
    |   Mount Point:               $ROOT_DIR/tests/tmp/Fedora Asahi Remix
EOF
printf '2\n' | RESTART_TO_LINUX_FORCE_INTERACTIVE=1 \
  RESTART_TO_LINUX_ALLOW_ANY_MOUNT=1 \
  RESTART_TO_LINUX_APFS_LIST_FILE="$ROOT_DIR/tests/tmp/apfs-list-ambiguous.txt" \
  "$ROOT_DIR/src/bin/restart-to-linux" --dry-run --bless-only 2>/dev/null | \
  grep -F 'Would run: bless --mount "'$ROOT_DIR'/tests/tmp/Fedora Asahi Remix" --setBoot' >/dev/null
RESTART_TO_LINUX_ALLOW_ANY_MOUNT=1 \
  RESTART_TO_LINUX_APFS_LIST_FILE="$ROOT_DIR/tests/fixtures/apfs-list.txt" \
  "$ROOT_DIR/src/bin/restart-to-linux" --dry-run --bless-only --target "$ROOT_DIR/tests/tmp/Arch Linux" | \
  grep -F 'Would run: bless --mount "'$ROOT_DIR'/tests/tmp/Arch Linux" --setBoot' >/dev/null
