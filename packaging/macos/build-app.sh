#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
APP_PATH=${APP_PATH:-"$ROOT_DIR/Restart to Linux.app"}
APP_CONTENTS="$APP_PATH/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
ICON_SOURCE="$ROOT_DIR/packaging/macos/AsahiLinux.icns"
LAUNCHER_SOURCE="$ROOT_DIR/src/applescript/restart-to-linux-launcher.applescript"
LAUNCHER_TEMPLATE="$ROOT_DIR/src/macos/restart-to-linux-launcher.sh"

rm -rf "$APP_PATH"
osacompile -o "$APP_PATH" "$LAUNCHER_SOURCE" >/dev/null
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$ROOT_DIR/src/applescript/restart-to-linux.applescript" "$APP_RESOURCES/restart-to-linux.applescript"
[ -f "$ICON_SOURCE" ] && cp "$ICON_SOURCE" "$APP_RESOURCES/AsahiLinux.icns"
if [ -f "$ICON_SOURCE" ]; then
  cp "$ICON_SOURCE" "$APP_RESOURCES/applet.icns"
  /usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$APP_CONTENTS/Info.plist" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile applet" "$APP_CONTENTS/Info.plist" >/dev/null 2>&1 || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string applet" "$APP_CONTENTS/Info.plist" >/dev/null
fi
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.jtbrough.restart-to-linux" "$APP_CONTENTS/Info.plist" >/dev/null 2>&1 || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.jtbrough.restart-to-linux" "$APP_CONTENTS/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(cat "$ROOT_DIR/VERSION")" "$APP_CONTENTS/Info.plist" >/dev/null 2>&1 || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $(cat "$ROOT_DIR/VERSION")" "$APP_CONTENTS/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(cat "$ROOT_DIR/VERSION")" "$APP_CONTENTS/Info.plist" >/dev/null 2>&1 || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $(cat "$ROOT_DIR/VERSION")" "$APP_CONTENTS/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c "Add :LSRequiresNativeExecution bool true" "$APP_CONTENTS/Info.plist" >/dev/null 2>&1 || \
  /usr/libexec/PlistBuddy -c "Set :LSRequiresNativeExecution true" "$APP_CONTENTS/Info.plist" >/dev/null

cp "$LAUNCHER_TEMPLATE" "$APP_MACOS/restart-to-linux-launcher"

sed -i.bak "s|__REPO_FALLBACK__|$ROOT_DIR/src/bin/restart-to-linux|g" "$APP_MACOS/restart-to-linux-launcher"
rm -f "$APP_MACOS/restart-to-linux-launcher.bak"

chmod +x "$APP_MACOS/restart-to-linux-launcher"

echo "Built app at $APP_PATH"
