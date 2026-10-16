#!/bin/sh
# Flatpak launcher for ZeroTier-GUI.
#
# The application source is installed under /app/share/zerotier-gui and is run
# with the Python interpreter shipped by the freedesktop runtime. The tkinter
# module (missing from the runtime) is built separately and installed into
# /app/lib/pythonX.Y/site-packages.

PYMAJMIN="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"

export PYTHONPATH="/app/lib/python${PYMAJMIN}/site-packages:${PYTHONPATH}"

# /app/bin must come first so the host-command wrappers (zerotier-cli,
# systemctl, pkexec) shadow anything else.
export PATH="/app/bin:/usr/sbin:/sbin:${PATH}"

exec python3 /app/share/zerotier-gui/zerotier-gui "$@"
