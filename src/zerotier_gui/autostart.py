"""XDG autostart entry management for launching the app in the tray."""

import os
import shlex
import shutil
import sys

AUTOSTART_FILENAME = "zerotier-gui.desktop"


def autostart_path():
    config_home = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    return os.path.join(config_home, "autostart", AUTOSTART_FILENAME)


def _icon_name():
    return os.environ.get("FLATPAK_ID") or "zerotier-gui"


def launch_command():
    if os.environ.get("FLATPAK_ID"):
        return f"flatpak run {os.environ['FLATPAK_ID']} --hidden"
    appimage = os.environ.get("APPIMAGE")
    if appimage:
        return f"{shlex.quote(appimage)} --hidden"
    executable = shutil.which("zerotier-gui")
    if executable:
        return f"{shlex.quote(executable)} --hidden"
    return f"{shlex.quote(sys.executable)} -m zerotier_gui.app --hidden"


def is_enabled():
    return os.path.isfile(autostart_path())


def set_enabled(enabled):
    path = autostart_path()
    if not enabled:
        try:
            os.remove(path)
        except FileNotFoundError:
            pass
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    entry = (
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Name=ZeroTier GUI\n"
        "Comment=Start ZeroTier GUI in the system tray\n"
        f"Exec={launch_command()}\n"
        f"Icon={_icon_name()}\n"
        "Terminal=false\n"
        "StartupNotify=false\n"
        "X-GNOME-Autostart-enabled=true\n"
    )
    temporary_path = path + ".tmp"
    with open(temporary_path, "w", encoding="utf-8") as stream:
        stream.write(entry)
    os.replace(temporary_path, path)
