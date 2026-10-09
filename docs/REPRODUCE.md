# Reproducing the patched libcamera build on Ubuntu 24.04

This walkthrough targets **Raspberry Pi 4 / ARM64 / Ubuntu 24.04 / libcamera 0.2.0**. Run Pi commands in a **Pi SSH shell**, except where explicitly labeled **Laptop**. Scripts are written to avoid installation into `/usr` or `/usr/local`.

## A. Confirm prerequisites

```bash
cat /etc/os-release
cat /proc/device-tree/model; echo
free -h
cam -l
command -v meson ninja patch
```

Check that the IMX219 appears under `cam -l` before proceeding. If camera detection fails, a libcamera patch is not sufficient to fix cabling/overlay/driver problems.

## B. Repository setup (one-time, reviewed)

Ubuntu minimal images sometimes contain only `noble` and `noble-security`, with `Types: deb` (no source packages). Back up the original:

```bash
sudo cp /etc/apt/sources.list.d/ubuntu.sources \
  /etc/apt/sources.list.d/ubuntu.sources.bak
```

Inspect the actual file before modifying it:

```bash
grep -E '^(Types|Suites|URIs|Components):' /etc/apt/sources.list.d/ubuntu.sources
```

If applicable, edit `/etc/apt/sources.list.d/ubuntu.sources` to include `deb-src` and `noble-updates` (preserve the existing URI, components and security stanza). On the tested image, these targeted replacements were appropriate:

```bash
sudo sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
sudo sed -i 's/^Suites: noble$/Suites: noble noble-updates/' /etc/apt/sources.list.d/ubuntu.sources
sudo apt update
```

**Do not** blindly change a different distribution's sources or run `apt full-upgrade` as part of this camera fix.

## C. Dependencies

```bash
sudo apt install --no-install-recommends \
  dpkg-dev patch build-essential meson ninja-build pkg-config \
  libyaml-dev python3-yaml python3-ply python3-jinja2 \
  libgnutls28-dev libevent-dev libudev-dev openssl \
  gstreamer1.0-tools gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  python3-pil
```

If APT proposes unexpected removal or modification of SSH/networking packages, stop and inspect `apt -s install ...` before continuing.

## D. Fetch Ubuntu's source

```bash
mkdir -p "$HOME/camera-fix"
cd "$HOME/camera-fix"
apt source libcamera
ls -ld libcamera-0.2.0
```

Check that `apt-cache policy libcamera0.2` shows `0.2.0-3fakesync1build6` for fidelity with the original test. `apt source` tracks available repository versions, so it may fetch a different release in the future. The patch script refuses to continue if expected source context is absent.

A `gpgv: Can't check signature: No public key` message means the `.dsc` signature was not verified with the locally installed keyring, even if extraction succeeded. Prefer trusted Ubuntu repositories and verify provenance as appropriate for your environment.

## E. Apply patch and build

Assuming this project was extracted to `~/rpi4-ubuntu24-imx219-libcamera-fix`:

```bash
bash "$HOME/rpi4-ubuntu24-imx219-libcamera-fix/scripts/build-patched-libcamera.sh" \
  "$HOME/camera-fix/libcamera-0.2.0"
```

The script checks for the patch and does not double-apply it. It sets:

```text
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
```

It then runs `ninja -C build -j 1`. On a Pi with 2 GB and no swap, avoid high parallelism. The build is intentionally local.

## F. Test the patched environment

```bash
bash "$HOME/rpi4-ubuntu24-imx219-libcamera-fix/scripts/test-capture.sh" \
  "$HOME/camera-fix/libcamera-0.2.0"
```

The script wraps **the local binary and IPA search paths** using Meson's `devenv`. Never mistake `cam -l` from `/usr/bin` for verification of the patched build.

Optional photo and streaming steps are in [STREAMING.md](STREAMING.md).

## G. Rollback

- Stop any Pi streaming process (`Ctrl+C`).
- The untouched distro `libcamera0.2` still exists because **no `ninja install` was executed**.
- To stop using the experiment, close the `meson devenv` session, or delete only `~/camera-fix` and the extracted project directory after backing up any wanted images.
- Repository sources backup is at `/etc/apt/sources.list.d/ubuntu.sources.bak` if needed. Restore it only after reviewing the file contents and impact on other software; then run `sudo apt update`.
- **Do not reboot or restart Wi-Fi just to test a camera patch.**
