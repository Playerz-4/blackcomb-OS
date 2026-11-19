BLACKCOMB FEDORA 45 SETUP KIT

This media contains the Fedora KDE Plasma Desktop live environment and Fedora's
Anaconda installer, with a Blackcomb live boot splash. If the live desktop is
black in a VM, reboot and choose "Start Blackcomb (basic graphics, no splash)"
in the boot menu. This fallback disables accelerated graphics and the splash;
it is for troubleshooting, and may not work on every VM.

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
