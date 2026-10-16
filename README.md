# ZeroTier-GUI <img src="img/zerotier-gui.png" align="bottom">

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg?style=flat-square)](https://github.com/tralph3/ZeroTier-GUI/blob/master/LICENSE)
[![Donate](https://img.shields.io/badge/Donate-PayPal-blue.svg?style=flat-square)](https://paypal.me/tralph3)

**A Linux front-end for ZeroTier**

The interface detects the desktop's light or dark appearance preference at
launch and uses a responsive layout inspired by the current ZeroTier Central
dashboard, with rounded cards and network status chips.

### Manage Networks
<img src="img/managenetworks1.png " width="1000">
<img src="img/managenetworks2.png " width="1000">

### Manage Peers
<img src="img/managepeers.png " width="1000">

# Installation

You can download the software from the [AUR](https://aur.archlinux.org/packages/zerotier-gui-git/).

    paru -S zerotier-gui-git

If you are in an Ubuntu/Debian based distribution, you can download the source code and run the `make_deb.sh` script.

    ./make_deb.sh

You may need to mark it as executable first:

    chmod +x make_deb.sh

**The script must be ran on the project's root folder, make sure to `cd` into it.**

The script will generate a `ZeroTier-GUI.deb` package in the root directory. Simply install it with `sudo apt install ./ZeroTier-GUI.deb`.

The package depends on `polkitd | policykit-1` (modern Debian/Ubuntu/Deepin
distributions ship `polkitd`, older ones `policykit-1`) and `python3-tk`.
`zerotier-one` is only a recommendation, so the package stays installable on
systems that use ZeroTier's own repository.

## AppImage

Builds a self-contained AppImage (Python and Tcl/Tk are bundled, so nothing
extra needs to be installed). Docker is used for a reproducible build.

    ./build-appimage.sh

This generates `ZeroTier-GUI.AppImage` in the project root. Run it with:

    chmod +x ZeroTier-GUI.AppImage
    ./ZeroTier-GUI.AppImage

## Flatpak

Builds a Flatpak bundle. Requires `flatpak` and `flatpak-builder`.

    ./build-flatpak.sh

Then install and run it with:

    flatpak install --user ./ZeroTier-GUI.flatpak
    flatpak run io.github.tralph3.ZeroTierGUI

The Flatpak runs the GUI sandboxed, but forwards `zerotier-cli`, `systemctl`
and `pkexec` to the host through `flatpak-spawn`, so it manages the same
`zerotier-one` service as a native install.

# ZeroTier access

ZeroTier-GUI talks to the running `zerotier-one` service through
`zerotier-cli`, which reads `/var/lib/zerotier-one/authtoken.secret`. The user
must belong to the `zerotier-one` group.

The application offers to set this up on first run. Because a new group
membership only becomes active after a new login (which is inconvenient when
launching from the application menu), the app transparently re-executes itself
inside the `zerotier-one` group using `sg` when needed, so no re-login is
required. The Flatpak build does the same on the host side.

# Building binaries with Docker

## Objective

This alternative aims to make ZeroTier-GUI available for multiple platforms using immutable infrastructure benefits, to avoid unexpected results depending where you are running these commands above.

## Setup

- install docker
- install Make (if not available)

## How-to

With Docker and Makefile available, you just need to run the following command:

```
make run
```

The expected result both ```rpm``` and ```deb``` files in project root. If you don't have Make available, you can run these commands line by line, as follows:

```
docker build . -t zero-tier-platforms-build:latest
docker create -ti --rm --name zero-tier-platforms-build zero-tier-platforms-build bash
docker cp zero-tier-platforms-build:/tmp/ZeroTier-GUI.deb ZeroTier-GUI.deb
docker cp zero-tier-platforms-build:/tmp/ZeroTier-GUI.rpm ZeroTier-GUI.rpm
docker rm -f zero-tier-platforms-build
```

# Dependencies

None of the packages contains the back-end, zerotier-one. Arch has it in the `community` repo. For Ubuntu based distributions, you'll need to install it manually [from their website](https://www.zerotier.com/download/). On top of that, you'll need python3.6 or greater, and the tkinter module. This however should be handled by the packaging software. Service management depends on SystemD. You will **not** be able to enable or disable the ZeroTier service without it.
