#!/usr/bin/env bash
# Copy a firmware project to an ASCII-only build path.
# Usage: bash scripts/prepare-ascii-build.sh /path/to/firmware
set -euo pipefail

SRC="${1:-${FIRMWARE_DIR:-}}"
if [[ -z "$SRC" || ! -f "$SRC/CMakeLists.txt" ]]; then
  echo "Usage: $0 /path/to/firmware (must contain CMakeLists.txt)" >&2
  exit 2
fi
SRC="$(cd "$SRC" && pwd -P)"
if LC_ALL=C grep -q '[^ -~]' <<< "$SRC"; then
  BASE="${SHANMAO1_BUILD_BASE:-$HOME/.cache/shanmao1-otto/build}"
  DEST="$BASE/firmware"
  mkdir -p "$DEST"
  echo "Copying non-ASCII source to ASCII build path: $DEST" >&2
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude build --exclude managed_components --exclude sdkconfig --exclude sdkconfig.old --exclude .git "$SRC/" "$DEST/"
  else
    (cd "$SRC" && tar --exclude=build --exclude=managed_components --exclude=sdkconfig --exclude=sdkconfig.old --exclude=.git -cf - .) | (cd "$DEST" && tar -xf -)
  fi
  echo "$DEST"
else
  echo "$SRC"
fi
