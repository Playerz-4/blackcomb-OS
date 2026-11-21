# blackpkdgs

`blackpkdgs` is Blackcomb's recommended application bundle for Fedora 45 KDE.

It installs:

- Firefox
- VLC
- LibreOffice Writer
- KCalc
- chafa
- ImageMagick

The RPM is a noarch metapackage, so it only declares dependencies and installs
the `blackpkdgs` helper command. Font config and the bundled neofetch script are
installed separately by `setup-blackcomb.sh`.

## Install

From the Blackcomb ISO or a local copy of the RPM:

```bash
sudo dnf install ./blackpkdgs.rpm
```

After installation, either of these installs the bundle:

```bash
sudo dnf install blackpkdgs
blackpkdgs
```

The helper command uses `sudo` when it is run as a normal user.
