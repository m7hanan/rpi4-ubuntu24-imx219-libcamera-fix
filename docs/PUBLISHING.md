# Publishing the project to GitHub

This project currently exists as a **prepared local repository**. No GitHub repository has been created or pushed automatically.

## Pre-publication review

- Verify repository includes **only** the small patch, scripts, and documentation; do not upload the complete Ubuntu/libcamera source, compiled binaries, camera captures, raw core dumps, or SSH keys.
- Credit upstream author **Elias Naur** and accepted libcamera patch 19446. Do not claim discovery of a new bug.
- Do not copy personal Wi-Fi passwords, school credentials, local user details, public IPs or private key material into logs.
- Confirm the tutorial's no-system-install and insecure-demo-stream caveats are visible.
- Run scripts in a test environment before marking them independently reproducible.

## Local Git initialization

```bash
cd rpi4-ubuntu24-imx219-libcamera-fix
git init
git add README.md LICENSE .gitignore QUICK_START_TAMIL.md docs scripts patches
git status
git commit -m "Document Ubuntu 24.04 libcamera IMX219 VC4 patch and streaming workflow"
```

## Publish with GitHub CLI (optional)

If `gh` is installed and you're logged in:

```bash
gh repo create rpi4-ubuntu24-imx219-libcamera-fix --private --source=. --remote=origin --push
```

Use `--public` only after review if you intend to share the documentation openly. You can alternatively create a repo in GitHub's web interface and follow the exact `git remote add origin ...` instructions supplied there.

## Suggested initial description

> Reproducing an accepted upstream libcamera VC4 embedded-buffer fix on Raspberry Pi 4 / Ubuntu 24.04; tested IMX219 capture and GStreamer LAN preview.

## Suggested release notes

**v0.1.0 — single-device reproduction (Oct 2026):** Recorded `prepareIsp()` assertion with libcamera 0.2.0 and IMX219, applied accepted upstream patch, locally rebuilt with Meson/Ninja, captured five 800×600 frames (exit 0), transferred a JPEG, and observed successful local video streaming. Build-time generated-serializer warnings remain to investigate.
