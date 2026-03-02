#!/bin/sh

set -eu

if [ "$#" -ne 2 ]; then
  echo "usage: $0 VERSION SHA256" >&2
  exit 1
fi

VERSION=$1
SHA256=$2
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
TEMPLATE="$ROOT_DIR/packaging/brew/restart-to-linux.rb.template"

[ -f "$TEMPLATE" ] || {
  echo "missing formula template: $TEMPLATE" >&2
  exit 1
}

sed \
  -e "s/__VERSION__/$VERSION/g" \
  -e "s/__SHA256__/$SHA256/g" \
  "$TEMPLATE"
