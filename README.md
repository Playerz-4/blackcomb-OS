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

#### Plasma start-up fix: Plymouth handoff plus KWin VM settings

The original black-screen symptom is a Plymouth/DRM handoff race. Fedora 45's `plasmalogin.service` already waits for `plymouth-quit.service` and runs `udevadm settle`; Blackcomb additionally ships drop-ins for **both** Plasma Login Manager and SDDM that wait and pause briefly, without using `plymouth-quit-wait.service` (which can create an ordering cycle). A per-seat PLM autologin override (`[Autologin][seat0]`), an SDDM fallback and a display-manager drop-in that rewrites each display manager's main config all reinforce Fedora's `liveuser`/`plasma.desktop` setting, avoiding a password prompt or wallpaper-only greeter if the main config's global values are ignored or overwritten by `livesys-late`. The splash and Plasma can therefore both run.

A wallpaper-and-cursor with no panels is a different failure: Fedora 45 KDE is Wayland-only, and KWin's atomic DRM mode-setting and hardware cursor plane are unreliable with VirtualBox's VMSVGA driver. The default boot entry now sets KDE's documented VM variables through `systemd.setenv=`:

- `KWIN_DRM_NO_AMS=1` — use KWin's legacy DRM interface instead of atomic mode-setting;
- `KWIN_FORCE_SW_CURSOR=1` — avoid the broken VM hardware cursor plane.

The same variables are also installed into the live user's Plasma environment. This is **not** safe graphics: modesetting remains enabled and accelerated. No `nomodeset`, `${basicgfx}` or extra safe-graphics entry is used.

The settings are copied into the writable live root by a dracut **pre-pivot hook** inside the existing `dracut-pre-pivot.service` — after the live overlay is mounted and before switch-root. It adds **no new systemd unit** to the boot transaction, runs no boot-critical command, and always returns 0, so it cannot put the session into emergency mode. The same hook is placed in every dracut hook directory (`/var/lib`, `/usr/lib`, `/lib` and `/etc`) because Fedora releases disagree on which one is scanned; dracut executes only the most privileged copy.

#### Live-session keyboard, display, wallpaper, taskbar and themes

The same hook applies these automatically, with no command from you:

- the live user can change the system keyboard layout and start Anaconda without a root-password prompt. The live-only polkit rule allows all actions in the disposable live session, including `org.freedesktop.locale1.*` for the keyboard/locale KCM and `org.freedesktop.policykit.exec` for the installer's pkexec helper. It does not depend on a username or "active" session flag, since KDE/KISS setup helpers can call D-Bus under a different account and live media has no root password. A matching legacy `.pkla` is installed as a fallback;
- a login autostart script asks KScreen for a modest screen mode (preferring 1024×768) in a virtual machine so Plasma fits a typical VirtualBox window. It also supports `xrandr` if an X11 session is present. Physical hardware is untouched;
- `kim-stargazer.png` is the initial live-session wallpaper, the Plasma session lock-screen wallpaper and the Plasma Login Manager/SDDM greeter wallpaper. All twelve Kim and Blackcomb backgrounds, including the two Christmas scenes, are installed as proper Plasma wallpaper packages under `/usr/share/wallpapers`, so they appear in the wallpaper picker rather than only as loose PNG files. The theme's default wallpaper is changed to Kim Stargazer, and the saved desktop layout is seeded directly with a valid `file:///.../kim-stargazer.png` image so the first boot cannot show a bare desktop. The main `plasmalogin.conf` and `kscreenlockerrc` are patched directly because some PLM releases ignore drop-in files. A small session helper remembers the last desktop wallpaper choice, so applying a global theme no longer replaces it with Fedora's wallpaper;
- **Breeze** is Blackcomb's default global theme — Fedora's standard Breeze, not a custom theme. The live session starts with OpenCode Catppuccin as its color scheme, while Breeze's standard Plasma components stay unchanged;
- the supplied `crescent-moon-start-icon.png` is applied automatically as the Plasma application-launcher icon, and the main Plasma panel is docked on the **left edge** as a vertical taskbar. It also gets standard **RAM**, **battery**, **GPU usage** and **digital clock** widgets. Plasma has no built-in analog speedometer face, so GPU usage uses the stock system-monitor bar with the `gpu/all/usage` sensor. No SVG editing or manual widget picking is needed;
- **Search Center** is a custom plain-QML applet on a centered bottom panel, uses the standard Breeze `system-search` icon and is bound to **Meta+N**. The panel button draws its magnifying glass in QML as well, so it stays visible even if the icon theme lacks that name. Press Meta+N or click its search icon to pull it upward: a search field sits at the top, pinned apps appear in a row, app suggestions come from KRunner, live search terms are fetched from Google's public suggestion endpoint, and DuckDuckGo, Google and Wikipedia web suggestions are always offered while typing. The live session enables KRunner's web-shortcut runner and a DuckDuckGo default provider so KRunner's own web suggestion also appears. The two most recent notifications are shown. The crescent **Kickoff** launcher still shows and manages pinned apps, and **Alt+Space** still opens KRunner directly. The earlier Dynamic Music applet has been scrapped; its old panel is removed during upgrade cleanup;
- **Meta+. (Super+period)** opens a companion **Emoji & Clipboard** panel in that same centered bottom bar. It offers Google Noto-style emoji (searchable by name and grouped into Faces, Hands, Nature, Food, Activities, Travel, Objects, Symbols and Flags), ASCII emoticons/kaomoji, common symbols, and clipboard history. Clicking any emoji, emoticon or symbol copies it to the system clipboard for pasting with Ctrl+V; the clipboard tab can also read and re-copy the current clipboard contents. Both the smiley and magnifier panel buttons are drawn in QML/Canvas, and the emoji picker uses Qt's normal font fallback rather than bundled artwork.

Both custom applets are installed from the media as plain QML KPackages. They add no SVG artwork, compiled helper or new binary dependency.
- `neofetch` shows that same crescent moon PNG through `chafa` instead of the default Fedora ASCII art. Fedora 45 does not ship neofetch in its base repositories, so Blackcomb bundles the upstream script (MIT licensed) and installs a `/usr/local/bin/neofetch` wrapper. It uses the real PNG when `chafa` and ImageMagick are installed and falls back to a bundled ASCII rendering of the same image on the live media. `setup-blackcomb.sh` installs `chafa`, ImageMagick and the wrapper on installed Fedora;
- OpenCode's built-in palettes are converted into 61 Plasma color schemes, including Catppuccin, Catppuccin Frappe, Catppuccin Macchiato, Dracula, Nord and TokyoNight. They are installed into `/usr/share/color-schemes/` and selectable under **System Settings → Appearance → Color Scheme**. The live session starts with **OpenCode Catppuccin**, and `setup-blackcomb.sh` installs the same set on an installed system. These are color schemes only; no icon or SVG artwork is changed.

The bundled `neofetch` comes from [dylanaraps/neofetch](https://github.com/dylanaraps/neofetch), pinned to commit `ccd5d9f52609bbdcd5d8fa78c4fdb0f12954125f` and licensed under the MIT license (see `third-party/neofetch/`).

The old opt-in script (`blackcomb/apply-live-fixes.sh`) is still shipped as a manual fallback for earlier media; you do not need it with this build.

For best results in VirtualBox, use **VMSVGA with 3D acceleration enabled**, one monitor and about 128 MB of video memory. KDE upstream states that 3D acceleration should be considered mandatory for Plasma 6 in VirtualBox; if you do not want 3D acceleration, VBoxSVGA with 3D disabled is the alternative. VirtualBox cannot truly follow the host window without Guest Additions. For exact window-following with the live ISO, use **View → Scaled Mode** on the host. In the installed system, install Guest Additions and enable **View → Auto-resize Guest Display**. If two pointers remain, turn off **View → Mouse Integration** on the host.

### VirtualBox black-screen and kernel-panic diagnostics

VirtualBox normally uses VMSVGA for Linux guests. Switching to VBoxSVGA is **not a confirmed fix** and has caused a kernel panic in a reported Blackcomb VM. If it causes trouble, power off the VM and restore its previous display settings.

A kernel panic has multiple possible causes. Capture a screenshot of the **complete panic message and lines above it**, along with your VirtualBox version and VM settings; do not assume it is the graphics controller. To reveal boot messages, select the normal boot entry, press `e`, remove `quiet` from the line beginning with `linux`, add `plymouth.enable=0` to the end of that same line, and press Ctrl+X or F10. This is a one-time diagnostic and does not change the ISO. If the screen remains black, include that result too.

The installed system receives the Blackcomb splash, twelve registered wallpaper packages, the standard Breeze global theme and the other assets only after manually running `blackcomb/setup-blackcomb.sh` from the installation media. Firmware logos shown before Linux starts are not changed.

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

### Wine support

`setup-blackcomb.sh` installs Fedora's Wine package, `winetricks`, `cabextract` and `unzip`, and registers Blackcomb Wine as the default launcher for `.exe`, `.msi`, `.bat` and `.lnk` files.

```bash
blackcomb-wine --check
blackcomb-wine ~/Downloads/Program.exe
blackcomb-wine ~/Downloads/Installer.msi
```

`blackcomb-wine` runs standard Windows executables, installers, batch files and shortcuts with Fedora's Wine. It does not run native macOS apps, `.app` bundles or `.dmg` images. Fedora's Wine build is 64-bit only, so some 32-bit Windows programs may still need a separate Wine setup.
