# Technical case study: `prepareIsp()` crash in libcamera 0.2.0

**Test date:** 9 October 2026  
**Category:** Embedded Linux / Raspberry Pi CSI camera / VC4 ISP / GStreamer  
**Outcome:** Working single-device camera capture with a locally patched libcamera build; JPEG transfer and live LAN viewing also achieved.

## 1. Context and environment

| Item | Observed configuration |
| --- | --- |
| Hardware | Raspberry Pi 4 Model B Rev 1.5 |
| Memory | 1.8 GiB reported usable (2 GB SKU), no swap |
| Operating system | Ubuntu 24.04.5 LTS (Noble Numbat) |
| Kernel | `6.8.0-1065-raspi` (aarch64) from SSH login banner |
| Camera sensor | Sony IMX219 CSI-2 (commonly Camera Module V2) |
| Camera integration | Unicam V4L2 capture + VC4 ISP / libcamera |
| Initially installed library | `libcamera0.2 0.2.0-3fakesync1build6` (arm64) |
| Toolchain | GCC 13.3.0, Meson 1.3.2, Ninja 1.11.1 |
| Access | Headless SSH over local phone hotspot |

The camera was physically connected to the Pi CSI connector. An end user needed image capture and a laptop live preview without switching operating systems.

## 2. Symptoms

Detection worked:

```text
$ cam -l
INFO RPI vc4.cpp:401 Registered camera .../imx219@10
... Unicam: /dev/media4, ISP: /dev/media0
Available cameras:
1: 'imx219' (.../imx219@10)
```

The ISP pipeline crashed as capture started:

```text
$ cam -c 1 --capture --file=frame.ppm
... configuring streams: (0) 800x600-XRGB8888
... Selected sensor format: 1640x1232-SBGGR10_1X10
FATAL default ipa_base.cpp:396 assertion "it != buffers_.end()" failed in prepareIsp()
Aborted (core dumped)
```

The original capture command had no frame limit (`--capture`), but the assertion occurred before a usable image was produced. The `.ppm` extension would not by itself guarantee a valid PPM image; `cam` writes camera buffer data.

## 3. Systematic diagnostics

1. `cat /proc/device-tree/model` confirmed the board as Pi 4 Model B Rev 1.5.
2. `ls /dev/video*`, `ls /dev/media*` showed video and media nodes, which **by themselves do not establish sensor functionality**.
3. `sudo dmesg | grep -Ei 'imx219|unicam|camera|csi'` showed the device-tree IMX219 node.
4. `/sys/bus/i2c/drivers/imx219/10-0010` confirmed kernel driver binding.
5. `/sys/class/video4linux/video0/name` returned `unicam-image`.
6. `v4l2-ctl --list-devices` associated `/dev/video0` and `/dev/media4` with `unicam` and `/dev/media0` with the Broadcom ISP.
7. `cam -l` registered the IMX219 with the VC4 pipeline, but `cam` capture crashed. This localized the failure to capture/ISP processing rather than simple sensor enumeration.

## 4. Root-cause investigation

The distro's libcamera 0.2.0 source was fetched with `apt source libcamera`. In the VC4 pipeline source file (`vc4.cpp`), `Vc4CameraData::tryRunPipeline()` used:

```cpp
ipa::RPi::PrepareParams params;
params.buffers.bayer = RPi::MaskBayerData | bayer;
params.sensorControls = std::move(bayerFrame.controls);
params.requestControls = request->controls();
params.ipaContext = request->sequence();
params.delayContext = bayerFrame.delayContext;

if (embeddedBuffer) {
    unsigned int embeddedId =
        unicam_[Unicam::Embedded].getBufferId(embeddedBuffer);
    params.buffers.embedded = RPi::MaskEmbeddedData | embeddedId;
}

ipa_->prepareIsp(params);
```

If `embeddedBuffer` is null, `params.buffers.embedded` remains uninitialized, making a spurious buffer identifier possible when the IPA processes the request.

**Upstream credit:** Elias Naur reported and patched this v0.2.0 issue in [libcamera patch 19446](https://patchwork.libcamera.org/patch/19446/), accepted as commit `0dc737d3e31112973c9286eb7775b8f730352a75`. The upstream report includes almost the same `prepareIsp()` assertion, with a line-number difference (`397` vs `396`) attributable to source/build variants. This case applies that pre-existing correction; it does **not** claim original bug discovery.

## 5. Intervention

A backup of `vc4.cpp` was taken. A single line was inserted before the conditional:

```diff
 params.delayContext = bayerFrame.delayContext;
+params.buffers.embedded = 0;

 if (embeddedBuffer) {
```

The library was configured for `rpi/vc4`, the RPi VC4 IPA, `cam`, and later the GStreamer plugin. It was built **locally** using Meson/Ninja; the distro package was not replaced.

The system initially lacked `deb-src` in APT sources, preventing extraction of source packages. It also lacked `noble-updates`, causing mismatched development dependencies. Both repositories were added with a backup of the source-list file. The single-job build (`ninja -j 1`) was selected because of the 2 GB RAM and no swap.

A generated serializer triggered GCC `-Wmaybe-uninitialized` diagnostics; since the project treated warnings as errors, compilation stopped. The evaluation build used `-Dwerror=false` to continue; **this does not resolve or dismiss the distinct serializer warnings**.

## 6. Measured validation

The patched `cam` detected the IMX219. Then:

```text
$ meson devenv -C build ./src/apps/cam/cam -c 1 --capture=5
cam0: Capture 5 frames
3537.185236 (0.00 fps) cam0-stream0 seq: 000007 bytesused: 1920000
3537.251958 (14.99 fps) cam0-stream0 seq: 000008 bytesused: 1920000
3537.318680 (14.99 fps) cam0-stream0 seq: 000009 bytesused: 1920000
3537.385404 (14.99 fps) cam0-stream0 seq: 000010 bytesused: 1920000
3537.452128 (14.99 fps) cam0-stream0 seq: 000011 bytesused: 1920000
$ echo $?
0
```

The test demonstrated five frames captured with no reproduction of the original assertion; 14.99 fps was the instantaneous rate reported for the last four frames, **not a sustained benchmark**.

A captured 800 × 600 XRGB8888 frame was converted to a JPEG (approximately 98 KB in the transfer log) and copied to the Ubuntu laptop using `scp`. A locally built `libgstlibcamera.so` plugin was located using `GST_PLUGIN_PATH`; `gst-inspect-1.0 libcamerasrc` identified the plugin, and the user subsequently confirmed successful live camera viewing over the phone-hotspot LAN.

## 7. Contribution boundaries

**What was achieved:** debugging, source inspection, reproduction of an accepted upstream fix, dependency resolution, local recompilation, IPA/camera validation, and GStreamer LAN integration.

**What was not achieved or claimed:** inventing a new library or upstream fix, production-hardening, long-run stability characterization, guaranteed camera support across kernels, or a secure externally accessible streaming service. The packaged Ubuntu libcamera installation was not overwritten.

## 8. Suggested follow-up engineering work

- Repeat 1000+ frame captures and log dropped frames, temperature, CPU load, and crashes.
- Confirm consistent color ordering when transforming XRGB8888 buffer data into JPEG.
- Measure MJPEG bandwidth and latency under varying hotspot load.
- Review GCC serializer warnings instead of relying indefinitely on `-Dwerror=false`.
- Add authenticated/encrypted transport (for example an SSH tunnel) before streaming across untrusted networks.
- Preserve the source-version pin, build flags and full logs for reproducibility.
