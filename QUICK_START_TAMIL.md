# Quick Start — தமிழ் வழிகாட்டி

இந்த repository புதிதாக உருவாக்கப்பட்ட camera library இல்லை. Ubuntu 24.04-ல் உள்ள **libcamera v0.2.0** source-க்கு ஏற்கெனவே upstream-ல் accepted ஆன **ஒரு வரி VC4 fix** apply செய்து, local build மூலம் test செய்வதற்கான documentation மற்றும் scripts.

## Raspberry Pi-ல் செய்ய வேண்டியது

1. Raspberry Pi 4 + IMX219 CSI camera connect ஆகியுள்ளதா `cam -l` மூலம் verify பண்ணுங்க.
2. `docs/REPRODUCE.md` பார்த்து `noble-updates` + `deb-src` repositories, build dependencies verify பண்ணுங்க.
3. Original Ubuntu libcamera source-ஐ `~/camera-fix/libcamera-0.2.0` directory-ல் extract பண்ணுங்க.
4. **இந்த project-ஐ Pi-யில் copy/clone செய்த பிறகு**, கீழே உள்ள commands பயன்படுத்தலாம் (இங்கே `~/rpi4-ubuntu24-imx219-libcamera-fix` என்பது project folder):

```bash
bash ~/rpi4-ubuntu24-imx219-libcamera-fix/scripts/build-patched-libcamera.sh \
  ~/camera-fix/libcamera-0.2.0

bash ~/rpi4-ubuntu24-imx219-libcamera-fix/scripts/test-capture.sh \
  ~/camera-fix/libcamera-0.2.0
```

5. Live camera தொடங்க (Pi terminal-ல்):

```bash
bash ~/rpi4-ubuntu24-imx219-libcamera-fix/scripts/stream-pi.sh \
  ~/camera-fix/libcamera-0.2.0
```

6. அதே Redmi hotspot / LAN-ல் உள்ள Ubuntu laptop-ல்:

```bash
bash ./scripts/view-laptop.sh Hanan.local
```

**கவனம்:** Video TCP port 5000-ல் encryption/password இல்லாமல் வருகிறது. Trusted Wi-Fi-க்கு மட்டும் பயன்படுத்துங்க. இந்த scripts original Ubuntu libcamera package-ஐ replace செய்யாது.

## இந்த project-ஐ GitHub-க்கு upload செய்ய

`docs/PUBLISHING.md`-ல் commands இருக்கின்றன. GitHub repo உருவாக்குவதற்கு முன் `.gitignore` மற்றும் files-ஐ review பண்ணுங்க.
