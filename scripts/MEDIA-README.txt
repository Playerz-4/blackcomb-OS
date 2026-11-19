BLACKCOMB 26.04 SETUP KIT

This media boots the original Ubuntu 26.04 desktop and Flutter-based Ubuntu
Desktop Bootstrap installer, not a preconfigured Plasma live session. Install
Ubuntu normally and reboot into the installed system. Connect to the internet,
then open a terminal and run:

  sudo bash /path/to/mounted-installer-media/blackcomb/setup-blackcomb.sh

Replace /path/to/mounted-installer-media with the actual mount path of this
USB drive or ISO. The installer does not automatically copy or run this kit.
Setup installs the Kubuntu desktop, Firefox, VLC, LibreOffice Writer and KCalc,
selects SDDM, sets the Blackcomb Plymouth boot theme (Ubuntu's spinner with the
Blackcomb logo), and installs wallpapers and branding. Firefox comes from the
Snap Store; setup requires internet access. Reboot, and select Plasma at login.
Existing Ubuntu desktop packages are not removed. The installer media's own
splash remains Ubuntu's.
After setup, run 'sudo blackcomb-plymouth --restore-ubuntu' to restore the
original Ubuntu BGRT loading screen.

To opt in to the GRUB menu background after setup, run:

  sudo blackcomb-grub-background

To use the launcher icon, right-click Plasma's application launcher, open its
settings, click the icon and choose the custom image at:

  /usr/share/blackcomb/branding/blackcomb-launcher.svg

See the project README for details, removal instructions and testing notes.
