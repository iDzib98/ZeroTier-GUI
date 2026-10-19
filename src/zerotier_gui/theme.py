"""System appearance detection and shared Qt Quick color palettes."""

import os
import subprocess

from PySide6.QtCore import Qt


PALETTES = {
    "light": {
        "background": "#f4f7fb",
        "surface": "#ffffff",
        "surfaceAlt": "#f7f9fc",
        "border": "#e3e8f0",
        "text": "#182230",
        "muted": "#697586",
        "accent": "#1769d2",
        "accentHover": "#0f58b8",
        "accentSoft": "#eaf2ff",
        "success": "#16845b",
        "successSoft": "#e8f6ef",
        "danger": "#c43d4b",
        "dangerSoft": "#fff0f0",
        "rowAlt": "#f7f9fc",
        "selection": "#dceaff",
        "input": "#ffffff",
        "shadow": "#160c1b2a",
    },
    "dark": {
        "background": "#111722",
        "surface": "#192230",
        "surfaceAlt": "#202b3b",
        "border": "#303d50",
        "text": "#e8edf5",
        "muted": "#9aa9bc",
        "accent": "#68a7ff",
        "accentHover": "#8bbaff",
        "accentSoft": "#253a57",
        "success": "#61c99b",
        "successSoft": "#1e3a33",
        "danger": "#ff8585",
        "dangerSoft": "#482b34",
        "rowAlt": "#1d2837",
        "selection": "#29456b",
        "input": "#141d29",
        "shadow": "#60000000",
    },
}


def _gsettings(schema, key):
    command = ["gsettings", "get", schema, key]
    if os.environ.get("FLATPAK_ID"):
        command = ["flatpak-spawn", "--host"] + command
    return subprocess.check_output(
        command,
        stderr=subprocess.DEVNULL,
        timeout=2,
        text=True,
        env=_clean_environment(),
    ).strip().strip("'\"").lower()


def _clean_environment():
    env = os.environ.copy()
    if getattr(__import__("sys"), "frozen", False):
        original = env.pop("LD_LIBRARY_PATH_ORIG", None)
        if original:
            env["LD_LIBRARY_PATH"] = original
        else:
            env.pop("LD_LIBRARY_PATH", None)
    return env


def detect_theme(application=None):
    if application is not None:
        try:
            scheme = application.styleHints().colorScheme()
            if scheme == Qt.ColorScheme.Dark:
                return "dark"
            if scheme == Qt.ColorScheme.Light:
                return "light"
        except AttributeError:
            pass

    if "dark" in os.environ.get("GTK_THEME", "").lower():
        return "dark"

    for schema, key in (
        ("com.deepin.dde.appearance", "gtk-theme"),
        ("com.deepin.xsettings", "theme-name"),
        ("org.gnome.desktop.interface", "color-scheme"),
        ("org.gnome.desktop.interface", "gtk-theme"),
    ):
        try:
            value = _gsettings(schema, key)
        except (OSError, subprocess.SubprocessError):
            continue
        if "dark" in value or value == "prefer-dark":
            return "dark"
        if value and value not in ("default", "prefer-light"):
            return "light"

    try:
        if os.environ.get("FLATPAK_ID"):
            for reader in ("kreadconfig6", "kreadconfig5"):
                try:
                    value = subprocess.check_output(
                        [
                            "flatpak-spawn",
                            "--host",
                            reader,
                            "--file",
                            "kdeglobals",
                            "--group",
                            "General",
                            "--key",
                            "ColorScheme",
                        ],
                        stderr=subprocess.DEVNULL,
                        timeout=2,
                        text=True,
                        env=_clean_environment(),
                    ).strip().lower()
                    if value:
                        return "dark" if "dark" in value else "light"
                except (OSError, subprocess.SubprocessError):
                    pass
            return "light"
        with open(
            os.path.expanduser("~/.config/kdeglobals"), encoding="utf-8"
        ) as stream:
            section = ""
            for line in stream:
                line = line.strip()
                if line.startswith("["):
                    section = line.lower()
                elif section == "[general]" and line.lower().startswith("colorscheme="):
                    return "dark" if "dark" in line.split("=", 1)[1].lower() else "light"
    except OSError:
        pass
    return "light"


def palette_for(theme):
    return PALETTES["dark" if theme == "dark" else "light"]
