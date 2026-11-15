#!/usr/bin/env bash
# Flash the Otto camera firmware.
# Usage:
#   bash scripts/flash.sh <PORT> [merged-binary.bin]        # full image, wipes NVS
#   bash scripts/flash.sh --app-only <PORT> [xiaozhi.bin]   # app only, keeps NVS
set -euo pipefail

APP_ONLY=0
if [[ "${1:-}" == "--app-only" ]]; then APP_ONLY=1; shift; fi
PORT="${1:-}"
BIN="${2:-}"

if [[ -z "$PORT" ]]; then
  echo "Usage: $0 [--app-only] <PORT> [bin]" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW="${FIRMWARE_DIR:-$HOME/.cache/shanmao1-otto/firmware}"
if [[ ! -f "$FW/CMakeLists.txt" && -f "$FW/firmware/voice/CMakeLists.txt" ]]; then
  FW="$FW/firmware/voice"
fi

IDF_DIR="${IDF_PATH:-$HOME/esp/esp-idf-v6.0.1}"
if [[ -f "$IDF_DIR/export.sh" ]]; then
  # shellcheck disable=SC1090
  source "$IDF_DIR/export.sh" >/dev/null 2>&1
fi

if [[ "$APP_ONLY" -eq 1 ]]; then
  BIN="${BIN:-$FW/build/xiaozhi.bin}"
  [[ -f "$BIN" ]] || { echo "ERROR: app image not found: $BIN" >&2; exit 1; }
  APP_OFFSET="0x20000"
  if [[ -f "$FW/build/flash_args" ]]; then
    OFFSET="$(awk '/xiaozhi\.bin$/ {print $1; exit}' "$FW/build/flash_args")"
    [[ -n "$OFFSET" ]] && APP_OFFSET="$OFFSET"
  fi
  echo "Flashing app only at $APP_OFFSET (NVS/Wi-Fi preserved): $BIN"
  esptool --chip esp32s3 -p "$PORT" -b 460800 write_flash "$APP_OFFSET" "$BIN"
  echo
  echo "Note: model/assets are NOT updated. If you changed wake-word model, GIFs, audio or locale, update those partitions too."
else
  BIN="${BIN:-$FW/build/merged-binary.bin}"
  [[ -f "$BIN" ]] || { echo "ERROR: merged image not found: $BIN" >&2; exit 1; }
  echo "WARNING: full image writes from 0x0 and will erase NVS / Wi-Fi provisioning."
  echo "Flashing: $BIN"
  esptool --chip esp32s3 -p "$PORT" -b 460800 write_flash 0x0 "$BIN"
fi
