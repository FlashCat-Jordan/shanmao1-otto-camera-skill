#!/usr/bin/env bash
# Build the Shanmao 1 Otto camera firmware from an ASCII-friendly path.
# Env:
#   FIRMWARE_DIR  existing firmware source (default: ~/.cache/shanmao1-otto/firmware)
#   WAKE_WORD     pretrained wake word (default: wn9_nihaoxiaozhi_tts)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW="${FIRMWARE_DIR:-$HOME/.cache/shanmao1-otto/firmware}"
WAKE_WORD="${WAKE_WORD:-wn9_nihaoxiaozhi_tts}"

if [[ ! -f "$FW/CMakeLists.txt" ]]; then
  echo "Firmware not found at $FW; cloning official xiaozhi-esp32..." >&2
  mkdir -p "$(dirname "$FW")"
  git clone --depth 1 https://github.com/78/xiaozhi-esp32.git "$FW"
fi

# Some repositories (e.g. Flashduck) keep the ESP-IDF project under firmware/voice.
if [[ ! -f "$FW/CMakeLists.txt" && -f "$FW/firmware/voice/CMakeLists.txt" ]]; then
  FW="$FW/firmware/voice"
fi
if [[ ! -f "$FW/scripts/build.py" ]]; then
  echo "ERROR: $FW does not look like the ESP-IDF project (missing scripts/build.py)." >&2
  exit 1
fi

# ESP-IDF 6.0.1 fails on non-ASCII paths on macOS.
if LC_ALL=C grep -q '[^ -~]' <<< "$FW"; then
  FW="$(bash "$ROOT/scripts/prepare-ascii-build.sh" "$FW" | tail -1)"
  echo "Building from ASCII path: $FW" >&2
fi

IDF_DIR="${IDF_PATH:-$HOME/esp/esp-idf-v6.0.1}"
if [[ ! -f "$IDF_DIR/export.sh" ]]; then
  echo "ERROR: ESP-IDF not found at $IDF_DIR. Run scripts/check-env.sh / setup-env.sh first." >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$IDF_DIR/export.sh" >/dev/null 2>&1

cd "$FW"
python3 scripts/build.py otto-robot \
  --name otto-robot \
  --language zh-CN \
  --wake-word "$WAKE_WORD"

echo
echo "Firmware project: $FW"
echo "Full image:      $FW/build/merged-binary.bin"
echo "App image:       $FW/build/xiaozhi.bin"
echo "Flash args:      $FW/build/flash_args"
