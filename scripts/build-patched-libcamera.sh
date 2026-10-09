#!/usr/bin/env bash
# Apply the accepted VC4 fix and compile locally (no system-wide install).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-$HOME/camera-fix/libcamera-0.2.0}"
PATCH="$ROOT/patches/0001-vc4-initialize-embedded-buffer.patch"
FILE="$SRC/src/libcamera/pipeline/rpi/vc4/vc4.cpp"

if [[ ! -f "$FILE" ]]; then
  echo "Missing libcamera source: $FILE" >&2
  echo "Fetch Ubuntu source with: mkdir -p ~/camera-fix && cd ~/camera-fix && apt source libcamera" >&2
  exit 1
fi
for tool in meson ninja patch; do
  command -v "$tool" >/dev/null || { echo "Missing command: $tool" >&2; exit 1; }
done

cd "$SRC"
if grep -Eq '^[[:space:]]*params\.buffers\.embedded = 0;' "$FILE"; then
  echo '[OK] Upstream initialization already present; not applying twice.'
else
  if ! patch --dry-run --batch -p1 < "$PATCH"; then
    echo '[ERROR] Patch does not apply cleanly. Confirm libcamera 0.2.0 version.' >&2
    exit 1
  fi
  patch --batch -p1 < "$PATCH"
fi

options=(
  --buildtype=release
  -Dpipelines=rpi/vc4
  -Dipas=rpi/vc4
  -Dcam=enabled
  -Dgstreamer=enabled
  -Dqcam=disabled
  -Dpycamera=disabled
  -Ddocumentation=disabled
  -Dtest=false
  -Dlc-compliance=disabled
  -Dwerror=false
)
if [[ -f build/build.ninja ]]; then
  echo '[INFO] Reconfiguring existing Meson build.'
  meson setup build --reconfigure "${options[@]}"
else
  meson setup build "${options[@]}"
fi

echo '[INFO] Building with one job (Pi 2 GB safe default).'
ninja -C build -j 1
printf '\n[OK] Local build complete. No system packages installed.\n'
printf 'Test: bash %q %q\n' "$ROOT/scripts/test-capture.sh" "$SRC"
