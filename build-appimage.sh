#!/bin/sh
#
# Build a self-contained AppImage for ZeroTier-GUI.
#
# Uses Docker so the build is reproducible and independent of the host
# distribution. The resulting AppImage bundles Python, PySide6 and Qt Quick
# via PyInstaller, so it runs on any x86_64 glibc-based distribution
# (Debian, Deepin, Ubuntu, Fedora, Arch, ...) without extra dependencies.

set -e

IMAGE="zerotier-gui-appimage"

docker build -f packaging/appimage/Dockerfile -t "${IMAGE}" .

container=$(docker create "${IMAGE}")
trap 'docker rm -f "${container}" >/dev/null 2>&1 || true' EXIT

docker cp "${container}:/build/ZeroTier-GUI.AppImage" ./ZeroTier-GUI.AppImage
chmod +x ./ZeroTier-GUI.AppImage

echo "Built: ./ZeroTier-GUI.AppImage"
