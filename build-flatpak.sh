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
BUILD_DIR="${TMPDIR:-/tmp}/zerotier-gui-flatpak-build"
REPO_DIR="${TMPDIR:-/tmp}/zerotier-gui-flatpak-repo"
STATE_DIR="${TMPDIR:-/tmp}/zerotier-gui-flatpak-state"

# Ensure the runtime and SDK are available (system or user installation).
for ref in \
    "org.freedesktop.Platform//${RUNTIME_VERSION}" \
    "org.freedesktop.Sdk//${RUNTIME_VERSION}"; do
    if ! flatpak info "${ref}" >/dev/null 2>&1; then
        flatpak install -y flathub "${ref}"
    fi
done

rm -rf "${BUILD_DIR}" "${REPO_DIR}" "${STATE_DIR}"
flatpak-builder --state-dir="${STATE_DIR}" --repo="${REPO_DIR}" \
    --force-clean "${BUILD_DIR}" "${MANIFEST}"
flatpak build-bundle "${REPO_DIR}" ZeroTier-GUI.flatpak "${APP_ID}"
rm -rf "${BUILD_DIR}" "${REPO_DIR}" "${STATE_DIR}" .flatpak-builder

echo "Built: ./ZeroTier-GUI.flatpak"
