#!/usr/bin/env bash
# Run on a laptop on same trusted LAN as the Raspberry Pi.
set -euo pipefail
HOST="${1:-raspberrypi.local}"
PORT="${2:-5000}"
command -v gst-launch-1.0 >/dev/null || { echo 'Install gstreamer1.0-tools and plugins on laptop.' >&2; exit 1; }
echo "Connecting to camera stream at $HOST:$PORT (Ctrl+C to stop)..."
gst-launch-1.0 \
  tcpclientsrc host="$HOST" port="$PORT" ! \
  multipartdemux ! jpegdec ! videoconvert ! autovideosink sync=false
