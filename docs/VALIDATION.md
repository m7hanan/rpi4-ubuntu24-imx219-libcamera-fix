# Validation evidence and limitations

Evidence in this document is drawn from the interactive troubleshooting session on **9 October 2026**. This is not a standardized performance or reliability test.

## Before the patch

- `cam -l`: IMX219 sensor listed.
- `/sys/bus/i2c/drivers/imx219/10-0010`: I²C sensor driver bound.
- `/dev/video0`: `unicam-image`.
- `cam -c 1 --capture --file=frame.ppm`: crashed while configuring the VC4 pipeline with `FATAL ... ipa_base.cpp:396 assertion "it != buffers_.end()" failed in prepareIsp()`; exit was an abort/core dump.

## After the patch, local-build verification

- Source diff contained exactly `+params.buffers.embedded = 0;` before `if (embeddedBuffer)`.
- `meson setup`: 39 targets reported with `rpi/vc4`, VC4 IPA, and `cam` enabled.
- `ninja`: first failed on GCC `-Wmaybe-uninitialized` warnings promoted by `-Werror` in generated IPA serializer; after `-Dwerror=false`, completed with warnings. These warnings are **not resolved**.
- `meson devenv -C build ./src/apps/cam/cam -l`: IMX219 listed.
- `meson devenv -C build ./src/apps/cam/cam -c 1 --capture=5`: logged five 800 × 600 XRGB8888 frames (1,920,000 bytes/frame), roughly 14.99 FPS for consecutive frames, and command exit code `0`.
- The patched `libgstlibcamera.so` was compiled; `GST_PLUGIN_PATH` allowed `gst-inspect-1.0 libcamerasrc` to find it, confirming the intended plugin path and metadata.
- JPEG transferred to laptop via SCP with `100%` transfer status (about 98 KB).
- User confirmed live local-network camera streaming succeeded. Exact sustained bitrate and end-to-end streaming FPS were **not independently measured**.

## Reproduction checklist

- [ ] `cam -l` with distro packages sees `imx219`.
- [ ] Original failing command/stack trace documented.
- [ ] Upstream patch applied exactly once.
- [ ] Compile succeeds (record warnings, build flags).
- [ ] Local `meson devenv` camera enumeration succeeds.
- [ ] Capture N frames with exit status 0.
- [ ] Inspect JPEG visually for correct orientation and channel order.
- [ ] Validate network stream on trusted local Wi-Fi.
- [ ] Repeat with stress/long-duration tests before deploying unattended.

## Limitations

Five frames are enough to verify the narrow regression test but not continuous stability. No systematic latency, quality, frame-loss, energy-use, or hot-plug tests were performed. The live stream has no built-in encryption/authentication; do not expose it to the public internet.
