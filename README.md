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

Blackcomb customizes Fedora's live boot menu and Plymouth splash with its logo. The main boot entry is **Boot Blackcomb**; Fedora's original basic graphics mode remains in the **Troubleshooting** submenu. It may help with some virtual-machine black screens but is not a guaranteed fix. Fedora's live desktop and Anaconda installer otherwise remain unchanged.

### VirtualBox black-screen and kernel-panic diagnostics

VirtualBox normally uses VMSVGA for Linux guests. Switching to VBoxSVGA is **not a confirmed fix** and has caused a kernel panic in a reported Blackcomb VM. If it causes trouble, power off the VM and restore its previous display settings.

A kernel panic has multiple possible causes. Capture a screenshot of the **complete panic message and lines above it**, along with your VirtualBox version and VM settings; do not assume it is the graphics controller. To reveal boot messages, select the normal boot entry, press `e`, remove `quiet` and `rhgb` from the line beginning with `linux`, add `plymouth.enable=0` to the end of that same line, and press Ctrl+X or F10. This is a one-time diagnostic and does not change the ISO. If the screen remains black, include that result too.

The **Troubleshooting → basic graphics** entry uses Fedora's original initrd, without the Blackcomb splash overlay. It also uses different graphics settings, so a different result alone does not identify the cause. To compare the normal entry with and without the overlay, select it, press `e`, and delete only `($root)/blackcomb-boot/plymouth.cpio` from the end of the `initrd` line; boot with Ctrl+X or F10. This is temporary and may show Fedora's splash instead.

If the VirtualBox window is too large to see, use **View → Scaled Mode** (Host+C) to fit it into the window. This scales the image, not the guest resolution. If two pointers appear, try toggling **Input → Mouse Integration** off; click inside the VM to capture the mouse and press the Host key to release it. The Host key is usually Right Ctrl on Windows/Linux and can be customized. Both are reversible host-side workarounds, not proven fixes for Plasma startup.

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
