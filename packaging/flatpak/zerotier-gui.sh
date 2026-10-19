#!/bin/sh
# Flatpak launcher for the PySide6/QML application.

PYMAJMIN="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"

export PYTHONPATH="/app/lib/python${PYMAJMIN}/site-packages:${PYTHONPATH:-}"

# /app/bin must come first so the host-command wrappers (zerotier-cli,
# systemctl, pkexec) shadow anything else.
export PATH="/app/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export QT_QUICK_CONTROLS_STYLE="Basic"

exec python3 -m zerotier_gui.app "$@"
