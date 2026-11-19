BLACKCOMB FEDORA 45 SETUP KIT

This media contains the Fedora KDE Plasma Desktop live environment and Fedora's
Anaconda installer, with a Blackcomb live boot splash. The normal boot entry is
named "Boot Blackcomb"; Fedora's basic graphics mode remains in the
Troubleshooting submenu. It may help with a black screen, but is not a
confirmed fix.

For VirtualBox, power off the VM completely, then try Display settings:
VBoxSVGA graphics controller, 128 MB video memory and 3D acceleration off.
This has helped some Fedora KDE users, but may not work for every VM; it can
reduce graphics performance. Windows hosts can alternatively run the optional
virtualbox-display-workaround.ps1 script from this folder, specifying the VM
name. The script prints the old settings and how to restore them. The VM must
be powered off (not saved). These settings are on the host, not inside the ISO.

To see boot messages, select "Boot Blackcomb", press e, remove quiet and rhgb
from the linux line, append plymouth.enable=0 to that line, then press Ctrl+X
or F10 to boot. These edits apply only to that boot.

The installer does not automatically copy or run the Blackcomb kit. Install
Fedora normally and reboot into the installed system. Connect to the internet,
mount this media, and run:

  sudo bash /path/to/mounted-installer-media/blackcomb/setup-blackcomb.sh

Replace the example path with the actual mount path. Setup uses Fedora's DNF
repositories for Firefox, VLC, LibreOffice Writer and KCalc; it installs the
wallpapers and the Blackcomb Plymouth theme, using the transparent logo. Reboot
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
