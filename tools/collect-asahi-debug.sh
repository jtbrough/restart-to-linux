#!/bin/sh

set -eu

timestamp=$(date +"%Y%m%d-%H%M%S")
log_file=${1:-"/tmp/restart-to-linux-debug-$timestamp.log"}

run() {
  printf '\n$ %s\n\n' "$*" >>"$log_file"
  if "$@" >>"$log_file" 2>&1; then
    :
  else
    status=$?
    printf '\n[exit status: %s]\n' "$status" >>"$log_file"
  fi
}

{
  echo "restart-to-linux debug capture"
  echo "timestamp: $(date)"
  echo "hostname: $(hostname)"
  echo "user: $(id -un)"
  echo "pwd: $(pwd)"
} >"$log_file"

run sw_vers
run uname -a
run diskutil list
run diskutil list -plist
run diskutil apfs list
run diskutil apfs list -plist
run mount
run bless --info
run ls -la /Volumes

cat <<EOF >>"$log_file"

Manual follow-up:

If you know the correct mounted Asahi target, rerun:
  $(basename "$0") "$log_file" "/Volumes/Your Target"

EOF

if [ "${2:-}" != "" ]; then
  target_path=$2
  run diskutil info "$target_path"
  run diskutil info -plist "$target_path"
fi

printf 'Wrote debug log to %s\n' "$log_file"
