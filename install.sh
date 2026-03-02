#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
default_prefix() {
  if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
    printf '%s\n' "/opt/homebrew"
    return
  fi

  printf '%s\n' "/usr/local"
}

PREFIX=${PREFIX:-$(default_prefix)}
BIN_DIR=${BIN_DIR:-"$PREFIX/bin"}
SHARE_DIR=${SHARE_DIR:-"$PREFIX/share/restart-to-linux"}
LIBEXEC_DIR=${LIBEXEC_DIR:-"$SHARE_DIR/libexec"}

install -d "$BIN_DIR" "$SHARE_DIR" "$LIBEXEC_DIR"
install -m 0755 "$ROOT_DIR/src/bin/restart-to-linux" "$BIN_DIR/restart-to-linux"
install -m 0755 "$ROOT_DIR/src/libexec/restart-to-linux-common" "$LIBEXEC_DIR/restart-to-linux-common"
install -m 0644 "$ROOT_DIR/VERSION" "$SHARE_DIR/VERSION"
install -m 0644 "$ROOT_DIR/src/applescript/restart-to-linux.applescript" "$SHARE_DIR/restart-to-linux.applescript"
install -m 0644 "$ROOT_DIR/src/applescript/restart-to-linux-launcher.applescript" "$SHARE_DIR/restart-to-linux-launcher.applescript"
install -m 0755 "$ROOT_DIR/src/macos/restart-to-linux-launcher.sh" "$SHARE_DIR/restart-to-linux-launcher.sh"
if [ -f "$ROOT_DIR/packaging/macos/AsahiLinux.icns" ]; then
  install -m 0644 "$ROOT_DIR/packaging/macos/AsahiLinux.icns" "$SHARE_DIR/AsahiLinux.icns"
fi

echo "Installed restart-to-linux to $PREFIX"
