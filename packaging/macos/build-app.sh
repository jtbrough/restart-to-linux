#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
APP_PATH=${APP_PATH:-"$ROOT_DIR/Restart to Linux.app"}
APP_CONTENTS="$APP_PATH/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
ICON_SOURCE="$ROOT_DIR/packaging/macos/AsahiLinux.icns"
LAUNCHER_SOURCE="$ROOT_DIR/src/applescript/restart-to-linux-launcher.applescript"

rm -rf "$APP_PATH"
osacompile -o "$APP_PATH" "$LAUNCHER_SOURCE" >/dev/null
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$ROOT_DIR/src/applescript/restart-to-linux.applescript" "$APP_RESOURCES/restart-to-linux.applescript"
[ -f "$ICON_SOURCE" ] && cp "$ICON_SOURCE" "$APP_RESOURCES/AsahiLinux.icns"
if [ -f "$ICON_SOURCE" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AsahiLinux" "$APP_CONTENTS/Info.plist" >/dev/null 2>&1 || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AsahiLinux" "$APP_CONTENTS/Info.plist" >/dev/null
fi
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.jtbrough.restart-to-linux" "$APP_CONTENTS/Info.plist" >/dev/null 2>&1 || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.jtbrough.restart-to-linux" "$APP_CONTENTS/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(cat "$ROOT_DIR/VERSION")" "$APP_CONTENTS/Info.plist" >/dev/null 2>&1 || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $(cat "$ROOT_DIR/VERSION")" "$APP_CONTENTS/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(cat "$ROOT_DIR/VERSION")" "$APP_CONTENTS/Info.plist" >/dev/null 2>&1 || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $(cat "$ROOT_DIR/VERSION")" "$APP_CONTENTS/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c "Add :LSRequiresNativeExecution bool true" "$APP_CONTENTS/Info.plist" >/dev/null 2>&1 || \
  /usr/libexec/PlistBuddy -c "Set :LSRequiresNativeExecution true" "$APP_CONTENTS/Info.plist" >/dev/null

cat >"$APP_MACOS/restart-to-linux-launcher" <<'EOF'
#!/bin/sh
set -eu

APP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RESOURCES_DIR=$APP_DIR/../Resources
CHOOSER_SCRIPT=$RESOURCES_DIR/restart-to-linux.applescript
DEBUG_LOG=/tmp/restart-to-linux-ui.log
REPO_FALLBACK=__REPO_FALLBACK__

show_dialog() {
  /usr/bin/osascript \
    -e 'use scripting additions' \
    -e 'on run argv' \
    -e 'display dialog (item 1 of argv) buttons {"OK"} default button "OK"' \
    -e 'end run' \
    -- "$1" >/dev/null
}

shell_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

find_tool() {
  if [ -x /opt/homebrew/bin/restart-to-linux ]; then
    printf '%s\n' /opt/homebrew/bin/restart-to-linux
    return
  fi

  if [ -x /usr/local/bin/restart-to-linux ]; then
    printf '%s\n' /usr/local/bin/restart-to-linux
    return
  fi

  if [ -x "$REPO_FALLBACK" ]; then
    printf '%s\n' "$REPO_FALLBACK"
    return
  fi

  return 1
}

tool_path=$(find_tool || true)
if [ -z "$tool_path" ]; then
  show_dialog "restart-to-linux is not installed."
  exit 1
fi

if ! candidate_output=$("$tool_path" --list 2>/tmp/restart-to-linux-ui-list.err); then
  error_text=$(cat /tmp/restart-to-linux-ui-list.err 2>/dev/null || true)
  rm -f /tmp/restart-to-linux-ui-list.err
  [ -n "$error_text" ] || error_text="No Linux boot targets were found."
  show_dialog "$error_text"
  exit 1
fi
rm -f /tmp/restart-to-linux-ui-list.err

set --
old_ifs=$IFS
IFS='
'
for candidate in $candidate_output; do
  [ -n "$candidate" ] || continue
  set -- "$@" "$candidate"
done
IFS=$old_ifs

if [ "$#" -eq 0 ]; then
  show_dialog "No Linux boot targets were found."
  exit 1
fi

if ! target_path=$(/usr/bin/osascript "$CHOOSER_SCRIPT" "$@" 2>/tmp/restart-to-linux-ui-choose.err); then
  status=$?
  error_text=$(cat /tmp/restart-to-linux-ui-choose.err 2>/dev/null || true)
  rm -f /tmp/restart-to-linux-ui-choose.err
  if [ "$status" -eq 1 ] && printf '%s' "$error_text" | /usr/bin/grep -q -- '-128'; then
    exit 0
  fi
  [ -n "$error_text" ] || error_text="Target selection failed."
  show_dialog "$error_text"
  exit 1
fi
rm -f /tmp/restart-to-linux-ui-choose.err

command_string="$(shell_quote "$tool_path") --debug-log $(shell_quote "$DEBUG_LOG") --target $(shell_quote "$target_path")"

/usr/bin/osascript \
  -e 'on run argv' \
  -e 'set shellCommand to item 1 of argv' \
  -e '«event sysoexec» shellCommand with «class badm»' \
  -e 'end run' \
  -- "$command_string"
EOF

sed -i.bak "s|__REPO_FALLBACK__|$ROOT_DIR/src/bin/restart-to-linux|g" "$APP_MACOS/restart-to-linux-launcher"
rm -f "$APP_MACOS/restart-to-linux-launcher.bak"

chmod +x "$APP_MACOS/restart-to-linux-launcher"

echo "Built app at $APP_PATH"
