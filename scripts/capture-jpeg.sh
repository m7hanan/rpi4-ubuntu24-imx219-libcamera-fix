#!/usr/bin/env bash
# Capture a raw 800x600 XRGB8888 frame and convert it to JPEG with Pillow.
# Tested workflow only; ensure pixel format/byte order before using for other sensors.
set -euo pipefail
SRC="${1:-$HOME/camera-fix/libcamera-0.2.0}"
CAP_DIR="${2:-$HOME/camera-fix/captures}"
mkdir -p "$CAP_DIR"
cd "$SRC"
[[ -x build/src/apps/cam/cam ]] || { echo 'Build the local cam executable first.' >&2; exit 1; }
meson devenv -C build ./src/apps/cam/cam -c 1 --capture=5 --file="$CAP_DIR/frame-#.bin"
python3 - "$CAP_DIR" <<'PYCODE'
from pathlib import Path
import sys
from PIL import Image

folder = Path(sys.argv[1])
frames = sorted(folder.glob('frame-*.bin'), key=lambda p: p.stat().st_mtime)
if not frames:
    raise SystemExit('No frame-*.bin output: inspect the cam capture log.')
frame = frames[-1]
raw = frame.read_bytes()
w, h = 800, 600
if len(raw) != w * h * 4:
    raise SystemExit(f'Unexpected frame size {len(raw)} for {frame}; expected {w*h*4}. Inspect stream format.')
image = Image.frombytes('RGB', (w, h), raw, 'raw', 'BGRX')
output = folder / 'camera-test.jpg'
image.save(output, quality=95)
print(f'[OK] Saved: {output}')
PYCODE
