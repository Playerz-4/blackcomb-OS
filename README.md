# Blackcomb OS

Blackcomb is an experimental Fedora-based KDE Plasma desktop concept featuring Kim the macaque. The base is **Fedora 45 KDE Plasma Desktop**, x86_64.

## What this builds

The build recompresses the Fedora KDE live filesystem inside the ISO and adds a Blackcomb post-install kit and wallpapers. It retains Fedora's live desktop and **Anaconda installer** rather than removing content. It does not otherwise customize the live desktop, live boot screen, or installer, and does not automatically install the kit. After installing Fedora and rebooting, run the kit to install Blackcomb artwork, a Plymouth boot theme and everyday apps. This is not an official Fedora image.

## Build installer media

On a Fedora build machine install the build tools with DNF. The builder requires root and EROFS loop-mount support to read the original filesystem with its metadata intact. Allow ample free space for the input ISO, two copies of the live filesystem and output ISO:

```sh
sudo dnf install xorriso curl isomd5sum coreutils erofs-utils util-linux rsync
sudo env FEDORA_ISO=/path/to/Fedora-KDE-Desktop-Live-45-1.4.x86_64.iso ./scripts/build-iso.sh
```

The input defaults to a download from the [Fedora KDE download page](https://fedoraproject.org/kde/download/). Its default SHA-256 is Fedora's published hash for the 45-1.4 x86_64 ISO. For authenticity, verify Fedora's signed checksum file using the instructions on that page. Set `ISO_SHA256` to a separately verified hash if using a different source; changing the hash does not bypass the Fedora 45 KDE volume and live filesystem checks. Run `./scripts/build-iso.sh --help` for overrides.

The script mounts the live EROFS filesystem read-only and rebuilds it using LZMA level 9, 1 MiB clusters and fragment deduplication. It then mounts both images and checks content and metadata with rsync before proceeding. The original ISO volume label and boot metadata are retained, `/blackcomb` is added, and a new Fedora media checksum is implanted and checked. The output is `blackcomb-fedora-45-x86_64.iso` and its SHA-256 sidecar. Verify with `sha256sum -c blackcomb-fedora-45-x86_64.iso.sha256` from the output directory. Use a sufficiently large USB drive or attach the ISO to a VM. Boot and installer compatibility must still be tested.

## Install and configure

1. Boot the ISO and install Fedora KDE using Anaconda. The live environment is Fedora's standard KDE desktop.
2. Reboot into the installed system, connect to the internet and mount the installer media. Run:

   ```sh
   sudo bash /path/to/mounted-installer-media/blackcomb/setup-blackcomb.sh
   ```

   Replace the example path with the actual mount path. Alternatively run `sudo ./scripts/setup-blackcomb.sh` from a checkout. This targets the standard installed Fedora 45 system, not an immutable variant or the live session. It uses DNF to install Firefox, VLC, LibreOffice Writer, KCalc and the Plymouth spinner theme, and installs Blackcomb artwork and a boot splash. Reboot afterward. Some media codecs are not included in Fedora's repositories; no third-party repositories are enabled by this kit.

The setup copies wallpapers to `/usr/share/backgrounds/blackcomb/`. A Plasma autostart helper sets `blackcomb-midnight.png` once per user; later wallpaper choices remain yours. The original supplied artwork is in `assets/reference/`.

## Boot logo, launcher and GRUB

Setup creates a separate Plymouth spinner theme using the transparent Blackcomb logo and rebuilds the installed system's initramfs. It does not overwrite Fedora's original spinner. Boot visuals depend on the graphics hardware and boot configuration. The installer media's own splash remains Fedora's. To refresh or reset the installed theme:

```sh
sudo blackcomb-plymouth
sudo blackcomb-plymouth --restore-fedora
```

To use the white crescent launcher SVG, right-click Plasma's application launcher, open its settings, click the icon and select `/usr/share/blackcomb/branding/blackcomb-launcher.svg`. This is a per-user choice, not an automatic panel change.

The optional GRUB menu background is separate from Plymouth. On a standard Fedora GRUB installation, `sudo blackcomb-grub-background` installs the image under `/boot/grub2/`, adds a managed setting in `/etc/default/grub`, and regenerates `/boot/grub2/grub.cfg`, never the EFI stub. To remove it, run `sudo blackcomb-grub-background --remove`. An existing GRUB theme or console mode, hidden menu, Secure Boot, firmware, or graphics support may prevent it from appearing. Test in a VM and back up first.

## GitHub Actions and size

Run **Build Blackcomb ISO** manually from Actions, supplying the verified input SHA-256. Every build recompresses the live filesystem inside the ISO using the `EROFS_COMPRESSION_LEVEL` set in the workflow YAML. The build runs Fedora tools in a privileged Fedora container on a GitHub-hosted runner; loop mounts require those privileges. It uploads the normal `.iso` and checksum as a three-day artifact. GitHub wraps artifact downloads in a ZIP; extract that download to obtain the `.iso`. A locally built ISO needs no extraction.

The job prints the original and recompressed live filesystem sizes and warns when the final ISO exceeds the **2 GiB target**. Fedora's original KDE ISO is about 3.3 GiB and already compressed; the final size depends on the actual build and is not guaranteed to reach 2 GiB. No installer or other content is intentionally removed. Higher compression can slow building and live operation; the installed system also needs more disk space. Hosted runner disk, time or artifact limits may require building on a larger machine.

## Testing and updates

This is an **experimental, unverified recipe**: the resulting image and post-install setup have not been tested end-to-end. Test media verification, BIOS and UEFI/secure boot, Anaconda installation, the Plasma login and Plymouth on a disposable VM and relevant hardware before relying on them. Follow Fedora's supported update and release-upgrade procedures. Fedora and KDE retain their own names, trademarks and licenses.
