#!/usr/bin/env bash
# Start unauthenticated MJPEG/TCP on a TRUSTED LAN only.
set -euo pipefail
SRC="${1:-$HOME/camera-fix/libcamera-0.2.0}"
PORT="${STREAM_PORT:-5000}"
# Default to Raspberry Pi's Wi-Fi IPv4 rather than listening on VPN/ethernet.
LAN_INTERFACE="${STREAM_INTERFACE:-wlan0}"
if [[ -n "${STREAM_BIND_IP:-}" ]]; then
  BIND="$STREAM_BIND_IP"
else
  BIND="$(ip -4 -o addr show dev "$LAN_INTERFACE" | awk 'NR==1 { split($4, a, "/"); print a[1] }')"
  [[ -n "$BIND" ]] || { echo "No IPv4 address on $LAN_INTERFACE; supply STREAM_BIND_IP explicitly." >&2; exit 1; }
fi
cd "$SRC"
[[ -f build/src/gstreamer/libgstlibcamera.so ]] || { echo 'Missing local GStreamer plugin. Build with -Dgstreamer=enabled.' >&2; exit 1; }
export GST_PLUGIN_PATH="$SRC/build/src/gstreamer${GST_PLUGIN_PATH:+:$GST_PLUGIN_PATH}"
export GST_REGISTRY="$HOME/.cache/libcamera-gst-registry.bin"
echo "[WARN] Unencrypted/unauthenticated MJPEG stream on $BIND:$PORT; trusted LAN only."
# Confirm the plugin is found without pager; do not rely on global gst registry.
meson devenv -C build env PAGER=cat gst-inspect-1.0 libcamerasrc >/dev/null
meson devenv -C build gst-launch-1.0 -e \
  libcamerasrc ! \
  'video/x-raw,colorimetry=bt709,format=NV12,width=640,height=480,framerate=15/1' ! \
  queue ! jpegenc quality=75 ! multipartmux ! \
  tcpserversink host="$BIND" port="$PORT"
