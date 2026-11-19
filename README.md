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

Blackcomb customizes Fedora's live boot menu and Plymouth splash with its logo. The live menu includes a **Start Blackcomb (basic graphics, no splash)** troubleshooting option for black screens; it may help with some virtual-machine display issues, but is not a guaranteed fix. Fedora's live desktop and Anaconda installer otherwise remain unchanged.

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
