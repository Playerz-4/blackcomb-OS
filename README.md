# Blackcomb OS

Blackcomb is an experimental Ubuntu-based desktop concept with KDE Plasma and Kim the macaque. The current target is **Ubuntu 26.04 LTS** (Resolute Raccoon), using the 26.04.1 desktop image. Standard Ubuntu security maintenance runs through April 2031.

## What this builds

The build script adds a Blackcomb setup kit and wallpapers to the official Ubuntu 26.04 desktop installer ISO, retaining Ubuntu's current boot splash, live desktop and **Flutter-based Ubuntu Desktop Bootstrap installer** (with Subiquity as its backend). The build leaves the installer unchanged; it does not replace it with Ubiquity. **It does not yet produce a preconfigured KDE live ISO or automatically install Blackcomb.** Install Ubuntu first, then run the included setup kit to add KDE Plasma, SDDM, wallpapers and a Blackcomb Plymouth loading screen. The theme uses the transparent Blackcomb logo with Ubuntu's BGRT spinner, and setup rebuilds the installed system's initramfs. The visible splash can vary by hardware and firmware.

Blackcomb keeps Ubuntu 26.04's desktop installer and layered, compressed live filesystem images. This kit is not an official Ubuntu or Kubuntu image.

## Build installer media

You need an amd64 host with `xorriso`, `curl`, `sha256sum`, and about 20 GB free disk space (more may be needed); no root access is needed to build. On Ubuntu:

```sh
sudo apt update
sudo apt install xorriso curl
```

Download the official `ubuntu-26.04.1-desktop-amd64.iso` and verify its SHA-256 against Ubuntu's [published checksums](https://releases.ubuntu.com/26.04/SHA256SUMS). For authenticity, verify the signed checksum file using Ubuntu's published signing keys and instructions. The build script verifies a supplied hash, but does not verify the signature itself.

```sh
UBUNTU_ISO=/path/to/ubuntu-26.04.1-desktop-amd64.iso \
ISO_SHA256='<verified sha256>' ./scripts/build-iso.sh
```

If `UBUNTU_ISO` is omitted the script downloads the official image. It warns if no `ISO_SHA256` is supplied. Run `./scripts/build-iso.sh --help` for output and working-directory overrides. It replays the original image's boot metadata and appends the kit under `/blackcomb`, leaving Ubuntu's boot files, filesystem layers and installer intact. It also updates `md5sum.txt` for the added files.

The output is `blackcomb-26.04-amd64.iso` and its `.sha256` file. Check the result with `sha256sum -c blackcomb-26.04-amd64.iso.sha256` from the output directory. Use a USB drive large enough for the ISO, or attach it to a VM.

## Install and configure

1. Boot the media and use the **Ubuntu Desktop Bootstrap Flutter installer** to install Ubuntu normally. The live environment is Ubuntu's standard desktop, not Plasma.
2. Reboot into the installed system and connect to the internet. Mount the installer media again if necessary.
3. Open a terminal and run the kit from the mounted media, replacing the example path with its actual location:

   ```sh
   sudo bash /path/to/mounted-installer-media/blackcomb/setup-blackcomb.sh
   ```

   Alternatively, from a checkout of this repository, run `sudo ./scripts/setup-blackcomb.sh`. The script confirms before installing `kubuntu-desktop`, Firefox, everyday apps, changing the default display manager to SDDM and installing the Blackcomb boot splash. It retains the existing Ubuntu desktop and installs the wallpapers. It is designed for an installed Ubuntu 26.04 system, not the live session. A reboot and selection of a Plasma session at login are required. Packages are downloaded from Ubuntu's repositories and the Snap Store, so this step requires network access.

The everyday app selection is Firefox (Ubuntu's Snap), VLC for media, LibreOffice Writer for documents and KCalc for calculations. The APT apps omit recommended extras to reduce downloads; additional codecs or features may require optional packages. These apps are installed by the post-install setup and are **not** preinstalled in the live ISO. The installed system requires much more than 2 GiB of disk space.

The wallpapers are installed to `/usr/share/backgrounds/blackcomb/`: `blackcomb-midnight.png`, `kim-alpine.png`, `blackcomb-blue-hour.png`, `kim-stargazer.png`, `blackcomb-aurora.png`, `kim-sunrise.png`, and `blackcomb-moonlit-forest.png`. The Plasma autostart helper applies `blackcomb-midnight.png` once per user; wallpaper choices can then be changed normally. The supplied source images are in `assets/reference/`.

## Branding, launcher and GRUB

The setup kit includes a transparent Blackcomb logo, a white crescent moon launcher SVG and a GRUB image from `assets/branding/`, installed to `/usr/share/blackcomb/branding/`. To use the launcher icon, right-click Plasma's application launcher, open its settings, click the icon and browse to `/usr/share/blackcomb/branding/blackcomb-launcher.svg`. This is a per-user choice; the setup does not modify an existing panel.

Setup also installs a separate Plymouth theme based on Ubuntu's BGRT spinner, using the transparent Blackcomb logo as its watermark and fallback image. It does not overwrite the Ubuntu theme files. If you already ran an older version of setup, update the kit and rerun setup to install the theme. After setup, `sudo blackcomb-plymouth` refreshes it and rebuilds the initramfs. To go back to Ubuntu's original BGRT theme, run `sudo blackcomb-plymouth --restore-ubuntu`. The manufacturer logo may still appear on BGRT-capable hardware. The original installer media's splash remains Ubuntu's; only the installed system is changed.

The GRUB menu background is **optional** and separate from the Plymouth loading screen. After setup, enable it with:

```sh
sudo blackcomb-grub-background
```

This installs the image under `/boot/grub/`, adds `/etc/default/grub.d/60-blackcomb-background.cfg`, and runs `update-grub`. The menu may be hidden by default; holding Shift or pressing Esc during boot can display it. To undo the change, remove the drop-in and image and regenerate the menu:

```sh
sudo rm -f /etc/default/grub.d/60-blackcomb-background.cfg /boot/grub/blackcomb-background.png
sudo update-grub
```

Bootloader configuration varies by hardware; test in a VM first. Neither the optional GRUB background nor the launcher setting is applied to the original Ubuntu installer live environment.

## GitHub Actions

Run **Build Blackcomb ISO** manually from the Actions tab and supply the official ISO's verified SHA-256. The workflow uploads the bootable `.iso` and its checksum as a three-day artifact, with the Ubuntu installer intact. GitHub Actions wraps downloaded artifacts in a ZIP: extract that ZIP to obtain the normal `.iso`, then verify it with `sha256sum -c blackcomb-26.04-amd64.iso.sha256`. A locally built `.iso` needs no extraction.

The job reports the ISO size and warns if it exceeds the **2 GiB target**. Ubuntu's 26.04.1 desktop ISO is already about 6 GB and its filesystem layers are already compressed, so this recipe cannot meet that target without changing the installer image. ISO builds can exceed hosted runner disk, time or artifact limits; use a larger machine if necessary.

## Updates and testing

Ubuntu 26.04 LTS provides standard security maintenance through April 2031, with extended coverage available under separate terms. Packages do not automatically become the newest versions yearly. This kit does not configure automatic release upgrades; follow Ubuntu's supported upgrade path and back up your data before upgrading.

This is an **untested experimental recipe**. Neither the generated ISO nor the post-install setup has been tested end-to-end. Test in a disposable VM before using real hardware, especially the installer, Plasma login, the resulting boot splash, BIOS/UEFI boot, and secure boot. Ubuntu and KDE retain their own names, trademarks and licenses.
