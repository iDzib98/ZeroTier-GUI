#!/bin/sh

# This script will create a deb package for ZeroTier-GUI

packageVersion=$(python3 -c "import re; print(re.search(r'__version__ = \"([^\"]+)\"', open('src/zerotier_gui/__init__.py').read()).group(1))")

# Clean previous deb staging (keep other packaging helpers)

rm -rf packaging/DEBIAN packaging/usr

# Create file structure

mkdir -pv packaging/DEBIAN
mkdir -pv packaging/usr/share/licenses/ZeroTier-GUI
mkdir -pv packaging/usr/share/pixmaps
mkdir -pv packaging/usr/share/applications
mkdir -pv packaging/usr/share/doc/ZeroTier-GUI
mkdir -pv packaging/usr/bin
mkdir -pv packaging/usr/lib/python3/dist-packages


# Copy files to corresponding directories

cp -vf LICENSE packaging/usr/share/licenses/ZeroTier-GUI
cp -vf img/zerotier-gui.png packaging/usr/share/pixmaps
cp -vf zerotier-gui.desktop packaging/usr/share/applications
cp -vf README.md packaging/usr/share/doc/ZeroTier-GUI
cp -vf src/zerotier-gui packaging/usr/bin
cp -R src/zerotier_gui packaging/usr/lib/python3/dist-packages/


# Create control file

echo "Package: zerotier-gui
Version: ${packageVersion}
Architecture: all
Maintainer: tralph3
Depends: python3 (>=3.11), python3-pyside6.qtquick, python3-pyside6.qtqml, python3-pyside6.qtwidgets, python3-pyside6.qtnetwork, qml6-module-qtqml, qml6-module-qtqml-workerscript, qml6-module-qtquick, qml6-module-qtquick-controls, qml6-module-qtquick-layouts, qml6-module-qtquick-window, iproute2, polkitd | policykit-1
Recommends: zerotier-one, systemd, python3-pyside6.qtdbus
Priority: optional
Homepage: https://github.com/tralph3/ZeroTier-GUI
Description: A Linux front-end for ZeroTier" > packaging/DEBIAN/control

# Build the package

dpkg-deb --root-owner-group --build packaging

# Rename the package

mv packaging.deb ZeroTier-GUI.deb
