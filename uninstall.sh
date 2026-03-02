#!/bin/sh

set -eu

default_prefix() {
  if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
    printf '%s\n' "/opt/homebrew"
    return
  fi

  printf '%s\n' "/usr/local"
}

PREFIX=${PREFIX:-$(default_prefix)}
BIN_PATH=${BIN_PATH:-"$PREFIX/bin/restart-to-linux"}
SHARE_DIR=${SHARE_DIR:-"$PREFIX/share/restart-to-linux"}

rm -f "$BIN_PATH"
rm -rf "$SHARE_DIR"

echo "Removed restart-to-linux from $PREFIX"
