Name:           blackpkdgs
Version:        1.0.0
Release:        1%{?dist}
Summary:        Blackcomb recommended application bundle

License:        MIT
URL:            https://github.com/Playerz-4/blackcomb-OS
BuildArch:      noarch
Source0:        blackpkdgs.sh
Source1:        blackpkdgs-README.md

Requires:       firefox
Requires:       vlc
Requires:       libreoffice-writer
Requires:       kcalc
Requires:       chafa
Requires:       imagemagick

%description
blackpkdgs is the Blackcomb application bundle for Fedora 45 KDE. It installs
Firefox, VLC, LibreOffice Writer, KCalc, chafa and ImageMagick, plus the
blackpkdgs helper command that can reinstall the bundle later.

%prep

%build

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/blackcomb/blackpkdgs
install -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/blackpkdgs
install -m 0644 %{SOURCE1} %{buildroot}%{_datadir}/blackcomb/blackpkdgs/README.md

%files
%{_bindir}/blackpkdgs
%{_datadir}/blackcomb/blackpkdgs/README.md

%changelog
* Sat Nov 21 2026 Blackcomb <https://github.com/Playerz-4/blackcomb-OS> - 1.0.0-1
- Initial Blackcomb application bundle.
