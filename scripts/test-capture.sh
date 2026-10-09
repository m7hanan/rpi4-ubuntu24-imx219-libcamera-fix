#!/usr/bin/env bash
# Test *locally built* libcamera and IPA modules, not distro /usr/bin/cam.
set -euo pipefail
SRC="${1:-$HOME/camera-fix/libcamera-0.2.0}"
cd "$SRC"
[[ -x build/src/apps/cam/cam ]] || { echo 'Missing built cam; run build-patched-libcamera.sh' >&2; exit 1; }
meson devenv -C build ./src/apps/cam/cam -l
meson devenv -C build ./src/apps/cam/cam -c 1 --capture=5
echo '[OK] Camera test command exited successfully.'
