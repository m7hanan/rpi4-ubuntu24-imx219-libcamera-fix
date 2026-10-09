# Troubleshooting notes

| Symptom | Likely area | Next check |
| --- | --- | --- |
| `No cameras available` | Camera/driver/overlay | `cam -l`, `sudo dmesg`, sensor binding, CSI cable orientation **with power off** |
| `dmesg: Operation not permitted` | Kernel log permissions | `sudo dmesg ...` |
| `cam -l` works but capture asserts in `prepareIsp()` | libcamera 0.2.0 VC4 bug | Verify applied upstream patch and test the **patched binary** |
| `E: You must put some 'deb-src' URIs ...` | APT source repository disabled | See `REPRODUCE.md` repository section |
| `libidn2-dev` / `nettle-dev` exact dependency mismatch | Noble update pocket not enabled | Confirm `noble-updates`; `apt-cache policy`; avoid downgrades |
| GCC `-Werror=maybe-uninitialized` stops build | Existing generated serializer warnings | Development-only `-Dwerror=false`; do not mistake for source fix |
| `meson devenv -C build -- ...` gives `Command not found: --` | Meson command syntax | Use `meson devenv -C build ./src/apps/cam/cam -l` (without `--`) |
| `meson devenv -C build ./build/src/apps/cam/cam` fails | `devenv` working directory is build | Use `./src/apps/cam/cam` |
| `No such element or plugin 'libcamerasrc'` | Plugin discovery | Export `GST_PLUGIN_PATH` to the *build/src/gstreamer* directory and run via `meson devenv` |
| `gst-inspect-1.0` opens a pager with HELP | Interactive pager | Press `q` to exit |
| SSH on a different Wi-Fi times out | Network, NAT, SSH/Tailscale | First check actual peer reachability, routes, SSH listener, and network policy |
| `Hanan.local` does not resolve | mDNS or phone hotspot | Use Pi's **current** LAN IPv4 address instead |
| Local stream connects but shows no frames | Negotiation/decoder/firewall | Run sender with `GST_DEBUG=2`; try negotiated NV12 caps; check port 5000 |

### Note on networking tools

On the recorded Pi, `wlan0` was managed by `systemd-networkd` with `/run/netplan/wpa-wlan0.conf`, whereas NetworkManager simultaneously reported Wi-Fi as `unavailable`. The connection itself was functional (`iw dev wlan0 link` showed the phone hotspot). A NetworkManager report alone can therefore be misleading; do not force NetworkManager to take over a remotely accessed Pi without a recovery plan.

### How to collect diagnostic output

```bash
cat /etc/os-release
cat /proc/device-tree/model; echo
cam -l
v4l2-ctl --list-devices
sudo dmesg | grep -Ei 'imx219|unicam|camera|csi' | tail -n 40
```

For a development-build GStreamer problem, use:

```bash
cd "$HOME/camera-fix/libcamera-0.2.0"
export GST_PLUGIN_PATH="$PWD/build/src/gstreamer${GST_PLUGIN_PATH:+:$GST_PLUGIN_PATH}"
export GST_REGISTRY="$HOME/.cache/libcamera-gst-registry.bin"
meson devenv -C build gst-inspect-1.0 libcamerasrc
```

Do not add the development library to `/etc/ld.so.conf` or overwrite the distro library just for diagnostics.
