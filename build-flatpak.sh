#!/bin/sh
# Build a Flatpak bundle for ZeroTier-GUI.
#
# Requires flatpak and flatpak-builder, and the matching freedesktop
# runtime/SDK (see RUNTIME_VERSION below). The resulting bundle can be
# installed on any distribution with:
#
#     flatpak install --user ./ZeroTier-GUI.flatpak

set -e

APP_ID="io.github.tralph3.ZeroTierGUI"
MANIFEST="${APP_ID}.yml"
RUNTIME_VERSION="25.08"

# Ensure the runtime and SDK are available (system or user installation).
if ! flatpak info "org.freedesktop.Sdk//${RUNTIME_VERSION}" >/dev/null 2>&1; then
    flatpak install -y flathub \
        "org.freedesktop.Platform//${RUNTIME_VERSION}" \
        "org.freedesktop.Sdk//${RUNTIME_VERSION}"
fi

flatpak-builder --repo=repo --force-clean build-dir "${MANIFEST}"
flatpak build-bundle repo ZeroTier-GUI.flatpak "${APP_ID}"

echo "Built: ./ZeroTier-GUI.flatpak"
