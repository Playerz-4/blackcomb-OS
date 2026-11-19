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
Plymouth keeps a graphics card busy while the SDDM login manager starts (Red
Hat bug 2404966). Blackcomb keeps the boot splash ("rhgb") and adds
"plymouth.use-simpledrm=0" so Plymouth uses the real graphics driver rather
than the early EFI framebuffer. The default entry also sets a 1024x768
framebuffer so the desktop fits a typical VirtualBox window. Hardware
acceleration is not disabled. If a machine still boots to black, edit the
boot line once and append plymouth.enable=0 to test whether Plymouth is
still involved.

LIVE SESSION KEYBOARD AND SCREEN SIZE:
Changing the system keyboard layout in KDE System Settings normally asks for
a root password, which live media does not have. This media allows the active
live user to make that one change without a password. In a virtual machine,
the live session also selects a modest screen mode (preferring 1024x768) at
login so the desktop fits a typical VirtualBox window.

VirtualBox cannot truly follow the host window without Guest Additions. For
exact window-following with this live media, use View > Scaled Mode on the
host. In the installed system, install Guest Additions and enable View >
Auto-resize Guest Display.

VirtualBox normally uses VMSVGA for Linux guests. Changing to VBoxSVGA is not
a confirmed fix and caused a kernel panic in one reported Blackcomb VM. If it
causes trouble, power off the VM and restore its previous display settings.
A kernel panic can have many causes; capture the full panic message and lines
above it, as well as the VirtualBox version and VM settings, for diagnosis.

To see boot messages, select "Boot Blackcomb", press e, remove quiet from the
linux line, append plymouth.enable=0 to that line, then press Ctrl+X or F10
to boot. These edits apply only to that boot.

The installer does not automatically copy or run the Blackcomb kit. Install
Fedora normally and reboot into the installed system. Connect to the internet,
mount this media, and run:

  sudo bash /path/to/mounted-installer-media/blackcomb/setup-blackcomb.sh

Replace the example path with the actual mount path. Setup uses Fedora's DNF
repositories for Firefox, VLC, LibreOffice Writer and KCalc; it installs the
wallpapers (with the stargazing image as the default) and the Blackcomb Plymouth
theme, using the transparent logo. Reboot
to see the installed-system theme. Firmware logos shown before the operating
system starts are not changed. Some media formats may require additional
codecs not supplied by Fedora.

To return to Fedora's default Plymouth theme, run:

  sudo blackcomb-plymouth --restore-fedora

For the optional GRUB menu background after setup, run:

  sudo blackcomb-grub-background

To use the launcher icon, right-click Plasma's application launcher, open its
settings, click the icon and choose the custom image at:

  /usr/share/blackcomb/branding/blackcomb-launcher.svg

See the project README for details, removal instructions and testing notes.
