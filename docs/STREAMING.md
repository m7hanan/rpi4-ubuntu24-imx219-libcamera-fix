# Camera capture and local live streaming

All Raspberry Pi commands below run on the **Pi** in the source tree, using its **locally compiled** libcamera. Laptop commands run on the Ubuntu desktop. The Pi and laptop must reach each other over the same trusted local network (e.g., a phone hotspot). Tailscale is not required for local access.

## 1. Frame capture sanity test (Pi)

```bash
bash scripts/test-capture.sh "$HOME/camera-fix/libcamera-0.2.0"
```

## 2. JPEG still frame (Pi)

```bash
bash scripts/capture-jpeg.sh "$HOME/camera-fix/libcamera-0.2.0"
```

The helper captures XRGB8888 camera buffer files, checks the expected byte length (800 × 600 × 4), and uses Pillow `BGRX` handling appropriate to the Pi's little-endian XRGB8888 output. A user should inspect the JPEG visually and validate channel order before generalizing this method to different pixel formats.

On the **laptop**:

```bash
scp hanan@Hanan.local:~/camera-fix/captures/camera-test.jpg ~/Pictures/
xdg-open ~/Pictures/camera-test.jpg
```

Replace SSH username, mDNS hostname or path to match your setup.

## 3. Start MJPEG/TCP streaming (Pi)

```bash
bash scripts/stream-pi.sh "$HOME/camera-fix/libcamera-0.2.0"
```

The helper exports `GST_PLUGIN_PATH` pointing to the development build and uses the current `wlan0` IPv4 address for the TCP listener by default. The equivalent **historical test pipeline** (which bound to all interfaces) was:

```bash
gst-launch-1.0 -e \
  libcamerasrc ! \
  'video/x-raw,colorimetry=bt709,format=NV12,width=640,height=480,framerate=15/1' ! \
  queue ! jpegenc quality=75 ! multipartmux ! \
  tcpserversink host=0.0.0.0 port=5000
```

The video feed is an unauthenticated TCP service on port **5000**. **Only run on a trusted, isolated LAN** and do not expose or port-forward it to the public internet. The **script** replaces `host=0.0.0.0` with the Pi's current Wi-Fi address by default, so it does not also listen on every VPN/Ethernet address. For a different interface, set `STREAM_INTERFACE=eth0`; for a particular explicit bind address, set `STREAM_BIND_IP=10.x.x.x`.

## 4. View live feed (laptop)

Install client-side elements on the laptop:

```bash
sudo apt install gstreamer1.0-tools gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good gstreamer1.0-x
```

Then:

```bash
bash scripts/view-laptop.sh Hanan.local
# or: bash scripts/view-laptop.sh 10.x.x.x
```

Underlying receiver:

```bash
gst-launch-1.0 tcpclientsrc host=Hanan.local port=5000 ! \
  multipartdemux ! jpegdec ! videoconvert ! autovideosink sync=false
```

Stop with Ctrl+C on both Pi and laptop terminal. If errors mention `not-negotiated`, try the smaller caps `video/x-raw,format=NV12,width=640,height=480,framerate=15/1`, inspect supported pad caps with `gst-inspect-1.0 libcamerasrc`, and report the exact logs.

## 5. Operational considerations

- Camera: IMX219, Raspberry Pi 4 (2 GB).
- Suggested baseline: 640 × 480 at 15 FPS and JPEG quality 75, chosen for modest CPU/network demands; actual sustained throughput depends on hardware and wireless link.
- For low latency, test dropped-frame and network behavior at the selected rate.
- If `GST_PLUGIN_PATH` is absent, `gst-inspect` may say `No such element or plugin 'libcamerasrc'`. The script sets the correct path automatically.
- If you need internet access, do not confuse it with local peer-to-peer connectivity: local SSH/video can work without remote Internet so long as both devices share a working LAN.
