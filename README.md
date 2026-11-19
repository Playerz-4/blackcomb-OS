# Blackcomb OS

Blackcomb is an experimental Ubuntu-based desktop concept with KDE Plasma and Kim the macaque. The current target is **Ubuntu 26.10** (Stonking Stingray), the latest Ubuntu release as of November 2026. It is an interim release, supported for nine months, until July 2027; it is not an LTS release.

## What this builds

The build script adds a Blackcomb setup kit and wallpapers to the official Ubuntu 26.10 desktop installer ISO, retaining Ubuntu's current boot splash, live desktop and interactive installer. **It does not yet produce a preconfigured KDE live ISO or automatically install Blackcomb.** Install Ubuntu first, then run the included setup kit to add KDE Plasma, SDDM and the wallpapers. The setup selects Ubuntu's BGRT Plymouth theme and refreshes the installed system's initramfs; the visible boot screen can vary by hardware and firmware.

Ubuntu's newer installer uses layered filesystem images instead of the single 22.04 Ubiquity filesystem. The old 22.04 remaster recipe is therefore not compatible with 26.10. This kit deliberately leaves the layers and installer unchanged rather than presenting an untested remaster as a working distribution. It is not an official Ubuntu or Kubuntu image.

## Build installer media

You need an amd64 host with `xorriso`, `curl`, `sha256sum`, and about 20 GB free disk space (more may be needed); no root access is needed to build. On Ubuntu:

```sh
sudo apt update
sudo apt install xorriso curl
```

Download the official `ubuntu-26.10-desktop-amd64.iso` and verify its SHA-256 against Ubuntu's [published checksums](https://releases.ubuntu.com/26.10/SHA256SUMS). For authenticity, verify the signed checksum file using Ubuntu's published signing keys and instructions. The build script verifies a supplied hash, but does not verify the signature itself.

```sh
UBUNTU_ISO=/path/to/ubuntu-26.10-desktop-amd64.iso \
ISO_SHA256='<verified sha256>' ./scripts/build-iso.sh
```

If `UBUNTU_ISO` is omitted the script downloads the official image. It warns if no `ISO_SHA256` is supplied. Run `./scripts/build-iso.sh --help` for output and working-directory overrides. It replays the original image's boot metadata and appends the kit under `/blackcomb`, leaving Ubuntu's boot files, filesystem layers and installer intact. It also updates `md5sum.txt` for the added files.

The output is `blackcomb-26.10-amd64.iso` and its `.sha256` file. Check the result with `sha256sum -c blackcomb-26.10-amd64.iso.sha256` from the output directory. Use a USB drive large enough for the ISO, or attach it to a VM.

## Install and configure

1. Boot the media and use the **Ubuntu installer** to install Ubuntu normally. The live environment is Ubuntu's standard desktop, not Plasma.
2. Reboot into the installed system and connect to the internet. Mount the installer media again if necessary.
3. Open a terminal and run the kit from the mounted media, replacing the example path with its actual location:

   ```sh
   sudo bash /path/to/mounted-installer-media/blackcomb/setup-blackcomb.sh
   ```

   Alternatively, from a checkout of this repository, run `sudo ./scripts/setup-blackcomb.sh`. The script confirms before installing `kubuntu-desktop` and changing the default display manager to SDDM. It retains the existing Ubuntu desktop and installs the wallpapers. It is designed for an installed Ubuntu 26.10 system, not the live session. A reboot and selection of a Plasma session at login are required. Packages are downloaded from Ubuntu's repositories, so this step requires network access.

The wallpapers are installed to `/usr/share/backgrounds/blackcomb/`: `blackcomb-midnight.png`, `kim-alpine.png`, `blackcomb-blue-hour.png`, and `kim-stargazer.png`. The Plasma autostart helper applies the first once per user; wallpaper choices can then be changed normally. The supplied source images are in `assets/reference/`.

## Branding, launcher and GRUB

The setup kit includes a transparent Blackcomb logo, a white Kim launcher SVG and a GRUB image from `assets/branding/`, installed to `/usr/share/blackcomb/branding/`. To use the launcher icon, right-click Plasma's application launcher, open its settings, click the icon and browse to `/usr/share/blackcomb/branding/blackcomb-launcher.svg`. This is a per-user choice; the setup does not modify an existing panel. The transparent `blackcomb-logo.png` is available for future boot-screen branding; it is not applied to Plymouth, so the Ubuntu loading screen remains unchanged.

The GRUB menu background is **optional** and separate from the Ubuntu Plymouth loading screen. After setup, enable it with:

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

Run **Build Blackcomb ISO** manually from the Actions tab and supply the official ISO's verified SHA-256. The workflow uploads the installer media and checksum as a three-day artifact. ISO builds are large and may exceed hosted runner disk, time or artifact limits; use a larger machine if necessary.

## Updates and testing

Ubuntu provides security and maintenance updates during the release's support window, but packages do not automatically become the latest versions yearly. This kit does not configure automatic release upgrades; follow Ubuntu's supported upgrade path and back up your data before upgrading. For longer support, Ubuntu 26.04 LTS is available, but it is not the latest release.

This is an **untested experimental recipe**. Neither the generated ISO nor the post-install setup has been tested end-to-end. Test in a disposable VM before using real hardware, especially the installer, Plasma login, the resulting boot splash, BIOS/UEFI boot, and secure boot. Ubuntu and KDE retain their own names, trademarks and licenses.
