# 🏔️ Blackcomb Linux

### Built on Fedora. Different by design.

**Blackcomb Linux** is a Fedora-based Linux distribution designed to provide a distinctive desktop experience while retaining the reliability, software availability, and familiarity of the Fedora ecosystem.

Powered by **KDE Plasma**, Blackcomb combines a customizable desktop environment with Fedora's package management, boot experience, and installation infrastructure.

The project aims to create a Linux distribution that feels like its own operating system rather than simply another Fedora installation with a different wallpaper.

---

# 🌌 About Blackcomb

Blackcomb is a community-oriented Linux distribution built around three main ideas:

- **Familiarity:** Retain the established Fedora foundations.
- **Customization:** Provide a distinct desktop experience through KDE Plasma.
- **Simplicity:** Make installation, software management, and everyday usage straightforward.

Rather than reinventing existing Linux infrastructure, Blackcomb builds upon technologies that are already established and widely supported.

The result is a distribution that combines Fedora's foundations with its own visual identity.

---

# 💻 System Requirements

These are **recommended starting points**, not tested minimums or a guarantee of compatibility. Blackcomb uses Fedora 45 KDE and currently builds an **x86_64 (64-bit Intel/AMD) ISO**. ARM devices need a compatible x86_64 emulator; an ARM Blackcomb ISO is not provided. Fedora recommends 4 GB RAM and 40 GB storage for most variants ([Fedora KDE download page](https://fedoraproject.org/kde/download/)).

## Physical computer

| Component | Recommended starting point | For a smoother experience |
| --- | --- | --- |
| Processor | 64-bit x86_64 Intel/AMD CPU, 2 cores | 4 or more cores |
| Memory | 4 GB RAM | 8 GB or more |
| Storage for installation | 40 GB available | 80 GB or more; SSD recommended |
| Display | Fedora-compatible graphics and a 1024 × 768 or larger display | Higher resolution as desired |
| Installation media | Bootable USB drive of at least 8 GB, or large enough for the ISO | A reliable USB 3 drive |
| Firmware | Computer able to boot the media using UEFI or legacy BIOS | UEFI recommended on modern PCs |

A keyboard and pointing device are recommended. An internet connection is needed for updates and the manual post-install Blackcomb setup, which downloads packages; the Fedora live environment and installer can be started offline. Back up important files before installing.

## Virtual machine

| VM setting | Recommended starting point | For a smoother experience |
| --- | --- | --- |
| Guest architecture | x86_64; attach the Blackcomb ISO as a virtual optical disk | Native x86_64 virtualization |
| Processors | 2 virtual CPUs | 4 virtual CPUs if the host has capacity |
| Guest memory | 4 GB RAM | 8 GB if the host has capacity |
| Virtual disk for installation | 40 GB | 80 GB or more for apps and files |
| VirtualBox video memory | 128 MB | 128 MB |

Use a compatible hypervisor such as VirtualBox, VMware, or QEMU/KVM. Hardware virtualization (Intel VT-x or AMD-V) should be enabled on the host when applicable. The host must have enough spare CPU, RAM, and disk space for both itself and the VM: **8 GB host RAM is a practical starting point**, with 16 GB or more preferable. A dynamically allocated virtual disk grows on the host as data is written; leave enough free space for its eventual size **plus the ISO**. These are guidance, not a promise that every host or graphics configuration will work.

For VirtualBox display troubleshooting, see [black-screen and kernel-panic diagnostics](#virtualbox-black-screen-and-kernel-panic-diagnostics) below. VM display-controller and 3D acceleration settings are host-specific, not universal requirements.

---

# ✨ Features

## 🐧 Fedora Foundation

Blackcomb uses Fedora as its underlying operating system.

This provides access to Fedora's software ecosystem, established package repositories, hardware support, and Linux infrastructure.

Benefits include:

- Access to Fedora software repositories.
- Compatibility with many Fedora applications.
- DNF package management.
- Modern Linux kernel and driver support.
- Access to Fedora documentation and community resources.

## 🖥️ KDE Plasma Desktop

Blackcomb uses KDE Plasma as its primary desktop environment.

KDE Plasma provides a flexible desktop experience with extensive customization possibilities.

Some of its capabilities include:

- Customizable panels and widgets.
- Multiple desktop layouts.
- Window management customization.
- Desktop themes and icons.
- System tray integration.
- Virtual desktops.
- Extensive appearance settings.

Blackcomb intends to establish its own visual identity rather than simply copying the default Fedora desktop.

## 🚀 Fedora Boot Experience

Blackcomb customizes Fedora's live boot menu and Plymouth splash with its logo, and applies a few live-session settings when the live desktop starts. The main boot entry is **Boot Blackcomb**; Fedora's original basic graphics mode remains in the **Troubleshooting** submenu. It may help with some virtual-machine black screens but is not a guaranteed fix. Fedora's live filesystem, desktop applications and Anaconda installer are otherwise unchanged.

#### Black-screen fix: splash kept, DRM handoff corrected

Fedora KDE 43+ can boot to a black screen because Plymouth holds a `/dev/dri/card*` device while SDDM/KWin starts ([Red Hat bug 2404966](https://bugzilla.redhat.com/show_bug.cgi?id=2404966)). Removing `rhgb` stops the splash but does not fix a VM whose framebuffer driver is also claiming a card. Blackcomb therefore **keeps `rhgb`** so the Blackcomb splash still appears, and adds `plymouth.use-simpledrm=0` — Fedora's documented switch that makes Plymouth wait for the real GPU driver instead of the early EFI framebuffer. The default entry also sets `video=1024x768` so the live desktop fits a typical VirtualBox window instead of scrolling. Hardware acceleration is **not** disabled: no `nomodeset` is used. The post-install setup applies the same Plymouth setting to installed kernels.

If a machine still boots to black, a one-time test with Plymouth fully disabled can isolate the handoff: select **Boot Blackcomb**, press `e`, append `plymouth.enable=0` to the line beginning with `linux`, and press Ctrl+X or F10.

#### Plasma start-up fix: SDDM waits for Plymouth

The black-screen/terminal-only symptom is a race: with `rhgb` kept, SDDM can start before Plymouth releases the GPU, so KWin cannot open `/dev/dri/card*` and Plasma never paints. A small `sddm.service` drop-in makes SDDM wait for `plymouth-quit.service` and pause briefly before starting. This keeps the splash **and** loads Plasma.

The drop-in is copied into the writable live root by a dracut **pre-pivot hook** inside the existing `dracut-pre-pivot.service` — after the live overlay is mounted and before switch-root. It adds **no new systemd unit** to the boot transaction, runs no boot-critical command, and always exits 0, so it cannot put the session into emergency mode.

#### Live-session keyboard, display and wallpaper

The same hook applies these automatically, with no command from you:

- the active live user can change the system keyboard layout without the **"Authentication is required to change the system keyboard layout"** root-password prompt (live media has no root password);
- a login autostart script asks KScreen for a modest screen mode (preferring 1024×768) in a virtual machine so Plasma fits a typical VirtualBox window. Physical hardware is untouched;
- `kim-stargazer.png` is the initial live-session wallpaper.

The old opt-in script (`blackcomb/apply-live-fixes.sh`) is still shipped as a manual fallback for earlier media; you do not need it with this build.

VirtualBox cannot truly follow the host window without Guest Additions. For exact window-following with the live ISO, use **View → Scaled Mode** on the host. In the installed system, install Guest Additions and enable **View → Auto-resize Guest Display**. A duplicate mouse pointer is normally VirtualBox pointer integration; Guest Additions or host mouse capture resolves it.

### VirtualBox black-screen and kernel-panic diagnostics

VirtualBox normally uses VMSVGA for Linux guests. Switching to VBoxSVGA is **not a confirmed fix** and has caused a kernel panic in a reported Blackcomb VM. If it causes trouble, power off the VM and restore its previous display settings.

A kernel panic has multiple possible causes. Capture a screenshot of the **complete panic message and lines above it**, along with your VirtualBox version and VM settings; do not assume it is the graphics controller. To reveal boot messages, select the normal boot entry, press `e`, remove `quiet` from the line beginning with `linux`, add `plymouth.enable=0` to the end of that same line, and press Ctrl+X or F10. This is a one-time diagnostic and does not change the ISO. If the screen remains black, include that result too.

The installed system receives the Blackcomb splash and other assets only after manually running `blackcomb/setup-blackcomb.sh` from the installation media. Firmware logos shown before Linux starts are not changed.

## 💿 Anaconda Installer

Blackcomb uses Fedora's Anaconda graphical installer rather than creating an entirely new installer.

This allows the project to build upon existing installation infrastructure.

The goal is to provide a straightforward installation experience for new and experienced Linux users.

## 📦 DNF Package Management

Blackcomb uses DNF, Fedora's familiar package management system.

Users can install, update, and remove applications through the terminal.

Example commands:

```bash
sudo dnf upgrade --refresh
sudo dnf install firefox
sudo dnf remove firefox
sudo dnf autoremove

```
