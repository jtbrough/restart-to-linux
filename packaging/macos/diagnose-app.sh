#!/bin/sh

set -eu

APP_PATH=${1:-"$HOME/Applications/Restart to Linux.app"}
APP_CONTENTS="$APP_PATH/Contents"
APP_INFO="$APP_CONTENTS/Info.plist"
APP_EXECUTABLE=""

print_section() {
  printf '\n== %s ==\n' "$1"
}

run_or_note() {
  printf '$ %s\n' "$*"
  if "$@"; then
    :
  else
    status=$?
    printf '[exit %s]\n' "$status"
  fi
}

if [ ! -d "$APP_PATH" ]; then
  printf 'app not found: %s\n' "$APP_PATH" >&2
  exit 1
fi

if [ -f "$APP_INFO" ]; then
  executable_name=$(/usr/bin/defaults read "$APP_INFO" CFBundleExecutable 2>/dev/null || true)
  if [ -n "$executable_name" ] && [ -e "$APP_CONTENTS/MacOS/$executable_name" ]; then
    APP_EXECUTABLE="$APP_CONTENTS/MacOS/$executable_name"
  elif [ -e "$APP_CONTENTS/MacOS/applet" ]; then
    APP_EXECUTABLE="$APP_CONTENTS/MacOS/applet"
  fi
fi

print_section "Bundle"
printf 'App: %s\n' "$APP_PATH"
printf 'Contents: %s\n' "$APP_CONTENTS"
if [ -n "$APP_EXECUTABLE" ]; then
  printf 'Executable: %s\n' "$APP_EXECUTABLE"
else
  printf 'Executable: not found\n'
fi

print_section "Finder Metadata"
run_or_note /bin/ls -la "$APP_PATH"
run_or_note /bin/ls -la "$APP_CONTENTS"
if [ -d "$APP_CONTENTS/MacOS" ]; then
  run_or_note /bin/ls -la "$APP_CONTENTS/MacOS"
fi
if [ -d "$APP_CONTENTS/Resources" ]; then
  run_or_note /bin/ls -la "$APP_CONTENTS/Resources"
fi

print_section "Info.plist"
if [ -f "$APP_INFO" ]; then
  run_or_note /usr/bin/plutil -p "$APP_INFO"
else
  printf 'missing: %s\n' "$APP_INFO"
fi

if [ -n "$APP_EXECUTABLE" ]; then
  print_section "Executable Inspection"
  run_or_note /usr/bin/file "$APP_EXECUTABLE"
  if [ ! -h "$APP_EXECUTABLE" ]; then
    run_or_note /usr/bin/lipo -archs "$APP_EXECUTABLE"
    run_or_note /usr/bin/otool -hv "$APP_EXECUTABLE"
  fi
fi

print_section "Code Signing"
run_or_note /usr/bin/codesign --verify --deep --strict --verbose=4 "$APP_PATH"
run_or_note /usr/bin/codesign -dv --verbose=4 "$APP_PATH"

print_section "Gatekeeper"
run_or_note /usr/sbin/spctl --assess --type execute --verbose=4 "$APP_PATH"

print_section "Spotlight"
run_or_note /usr/bin/mdfind "kMDItemFSName == 'Restart to Linux.app'"

print_section "LaunchServices"
run_or_note /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump

print_section "Launch Attempt"
run_or_note /usr/bin/open "$APP_PATH"

if [ -n "$APP_EXECUTABLE" ] && [ -x "$APP_EXECUTABLE" ]; then
  print_section "Direct Executable Attempt"
  run_or_note "$APP_EXECUTABLE"
fi
