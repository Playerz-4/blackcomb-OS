BLACKCOMB FEDORA 45 SETUP KIT

SYSTEM REQUIREMENTS (recommended starting points, not tested minimums)

Physical PC: 64-bit Intel/AMD x86_64 CPU with 2 or more cores, 4 GB RAM,
40 GB available installation storage, compatible graphics and a 1024x768
or larger display. For smoother use, choose 8 GB RAM and an SSD with 80 GB
or more available. Use an 8 GB or larger USB drive to create installation media.
The computer must be able to boot the media using UEFI or legacy BIOS.

Virtual machine: x86_64 guest, 2 virtual CPUs, 4 GB guest RAM, 40 GB virtual
disk for installation and the ISO attached as a virtual optical disk. For
smoother use, allocate 4 CPUs and 8 GB guest RAM if the host has capacity.
Enable Intel VT-x or AMD-V on the host when applicable. Allow enough resources
for the host too: 8 GB host RAM is a practical starting point; 16 GB or more
is preferable. A dynamically allocated disk grows as used, so allow space for
its eventual size and the ISO. In VirtualBox, try 128 MB video memory.

Internet access is needed for updates and the manual Blackcomb setup, but not
to start the Fedora live environment or installer. Compatibility and VM
performance depend on the hardware and hypervisor. No ARM Blackcomb ISO is
currently provided.

This media contains the Fedora KDE Plasma Desktop live environment and Fedora's
Anaconda installer, with a Blackcomb live boot splash. The normal boot entry is
named "Boot Blackcomb"; Fedora's basic graphics mode remains in the
Troubleshooting submenu. It may help with a black screen, but is not a
confirmed fix.

BLACK SCREEN AFTER THE BOOT SPLASH:
Fedora KDE 43+ can leave a black screen instead of the Plasma desktop when
Plymouth keeps a graphics card busy while the login manager starts (Red Hat
bug 2404966). Blackcomb keeps the boot splash ("rhgb") and adds
"plymouth.use-simpledrm=0" so Plymouth uses the real graphics driver rather
than the early EFI framebuffer. The default entry also sets a 1024x768
framebuffer so the desktop fits a typical VirtualBox window. Hardware
acceleration is not disabled. If a machine still boots to black, edit the
boot line once and append plymouth.enable=0 to test whether Plymouth is
still involved.

PLASMA WALLPAPER BUT NO PANELS IN VIRTUALBOX:
Fedora 45 KDE is Wayland-only. KWin's atomic DRM mode setting and hardware
cursor plane are unreliable with VirtualBox's VMSVGA driver, so the default
boot entry also sets KWIN_DRM_NO_AMS=1 and KWIN_FORCE_SW_CURSOR=1 through
systemd.setenv. These are KDE's documented VM settings: legacy DRM interface
plus a software cursor. They are not safe graphics; modesetting stays on.

LIVE SESSION START-UP, KEYBOARD, SCREEN SIZE, TASKBAR AND THEMES:
Drop-ins are supplied for both SDDM and Fedora 44+'s Plasma Login Manager;
Fedora 45 uses the latter. A per-seat autologin override reinforces the
liveuser/plasma.desktop session. A virtual machine picks a modest screen mode
(preferring 1024x768) at login, the live user can change the system keyboard
layout or locale without the root-password prompt, kim-stargazer is the desktop and
login-screen wallpaper, all seven Kim and Blackcomb backgrounds are registered as
Plasma wallpaper packages and appear in the wallpaper picker, Mountain is the
default global theme and follows the active Plasma color scheme, the supplied
crescent-moon-start-icon.png is set as the launcher icon, and the Plasma panel
is docked on the left as a vertical taskbar. The bundled neofetch command shows
that crescent image through chafa, or a bundled ASCII rendering of it when chafa
or ImageMagick is absent. OpenCode's built-in palettes are installed as 61 Plasma
color schemes, selectable in System Settings > Appearance > Color Scheme; the
live session starts with OpenCode Catppuccin. No command is needed for the theme.
A dracut pre-pivot hook copies these settings into the live session as it starts;
it adds no boot-critical unit, so booting is unaffected.

The apply-live-fixes.sh script on this media is only a manual fallback for
older Blackcomb media. You do not need it with this build.

For best results, use VirtualBox VMSVGA with 3D acceleration enabled, one
monitor and about 128 MB video memory. KDE upstream says 3D acceleration
should be considered mandatory for Plasma 6 in VirtualBox. If you do not want
3D acceleration, the alternative is VBoxSVGA with 3D disabled; if you had a
kernel panic with VBoxSVGA before, power off the VM and restore its earlier
display settings. VirtualBox cannot truly follow the host window without
Guest Additions. For exact window-following with this live media, use View >
Scaled Mode on the host. In the installed system, install Guest Additions
and enable View > Auto-resize Guest Display. If two pointers remain, turn off
View > Mouse Integration on the host.

To see boot messages, select "Boot Blackcomb", press e, remove quiet from the
linux line, append plymouth.enable=0 to that line, then press Ctrl+X or F10
to boot. These edits apply only to that boot.

The installer does not automatically copy or run the Blackcomb kit. Install
Fedora normally and reboot into the installed system. Connect to the internet,
mount this media, and run:

  sudo bash /path/to/mounted-installer-media/blackcomb/setup-blackcomb.sh

Replace the example path with the actual mount path. Setup uses Fedora's DNF
repositories for Firefox, VLC, LibreOffice Writer, KCalc, chafa, ImageMagick,
Wine, winetricks, cabextract and unzip; neofetch is bundled on this media. Setup
installs all seven wallpaper packages (with stargazing as the default), the
Mountain global theme, the left-side vertical taskbar, the neofetch crescent
image, the OpenCode Plasma color schemes (with OpenCode Catppuccin as the
default), the Blackcomb Update launcher, Wine file associations and the
Blackcomb Plymouth theme, using the transparent logo. After setup, find Blackcomb
Update under Settings or run "blackcomb-update". It checks GitHub Releases,
verifies the release checksum, upgrades Fedora packages and refreshes Blackcomb
assets. Run "blackcomb-wine" to launch Windows apps or Wineskin-style macOS .app
wrappers; true Mach-O macOS apps are not supported by Wine. Reboot to see the
installed-system theme. Firmware logos shown before the operating system starts
are not changed. Some media formats may require additional codecs not supplied
by Fedora.

To return to Fedora's default Plymouth theme, run:

  sudo blackcomb-plymouth --restore-fedora

For the optional GRUB menu background after setup, run:

  sudo blackcomb-grub-background

The custom launcher icon is applied automatically at login from:

  /usr/share/blackcomb/branding/crescent-moon-start-icon.png

If you want to choose it again manually, right-click Plasma's application
launcher, open its settings, click the icon and select that PNG file.

See the project README for details, removal instructions and testing notes.
