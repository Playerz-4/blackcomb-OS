BLACKCOMB FEDORA 45 SETUP KIT

This media contains the original Fedora KDE Plasma Desktop live environment
and Fedora's Anaconda installer. The installer does not automatically copy or
run the Blackcomb kit. Install Fedora normally and reboot into the installed
system. Connect to the internet, mount this media, and run:

  sudo bash /path/to/mounted-installer-media/blackcomb/setup-blackcomb.sh

Replace the example path with the actual mount path. Setup uses Fedora's DNF
repositories for Firefox, VLC, LibreOffice Writer and KCalc; it installs the
wallpapers and the Blackcomb Plymouth theme, using the transparent logo. Reboot
to see the theme. It does not change the installer's own boot splash. Some
media formats may require additional codecs not supplied by Fedora.

To return to Fedora's default Plymouth theme, run:

  sudo blackcomb-plymouth --restore-fedora

For the optional GRUB menu background after setup, run:

  sudo blackcomb-grub-background

To use the launcher icon, right-click Plasma's application launcher, open its
settings, click the icon and choose the custom image at:

  /usr/share/blackcomb/branding/blackcomb-launcher.svg

See the project README for details, removal instructions and testing notes.
