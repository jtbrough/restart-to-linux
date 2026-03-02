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

  if [ -n "$REPO_FALLBACK" ] && [ -x "$REPO_FALLBACK" ]; then
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

list_err=$(mktemp /tmp/restart-to-linux-ui-list.XXXXXX.err)
choose_err=$(mktemp /tmp/restart-to-linux-ui-choose.XXXXXX.err)
trap 'rm -f "$list_err" "$choose_err"' EXIT HUP INT TERM

if ! candidate_output=$("$tool_path" --list 2>"$list_err"); then
  error_text=$(cat "$list_err" 2>/dev/null || true)
  [ -n "$error_text" ] || error_text="No Linux boot targets were found."
  show_dialog "$error_text"
  exit 1
fi

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

if ! target_path=$(/usr/bin/osascript "$CHOOSER_SCRIPT" "$@" 2>"$choose_err"); then
  status=$?
  error_text=$(cat "$choose_err" 2>/dev/null || true)
  if [ "$status" -eq 1 ] && printf '%s' "$error_text" | /usr/bin/grep -q -- '-128'; then
    exit 0
  fi
  [ -n "$error_text" ] || error_text="Target selection failed."
  show_dialog "$error_text"
  exit 1
fi

command_string="$(shell_quote "$tool_path") --debug-log $(shell_quote "$DEBUG_LOG") --target $(shell_quote "$target_path")"

/usr/bin/osascript \
  -e 'on run argv' \
  -e 'set shellCommand to item 1 of argv' \
  -e '«event sysoexec» shellCommand with «class badm»' \
  -e 'end run' \
  -- "$command_string"
