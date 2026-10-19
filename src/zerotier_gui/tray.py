"""System tray integration: native menu and background notifications."""

import os
import sys
from pathlib import Path

from PySide6.QtCore import QObject
from PySide6.QtGui import QIcon
from PySide6.QtWidgets import QMenu, QSystemTrayIcon

from . import autostart

NETWORK_OPTIONS = (
    ("allowDefault", "Allow default route"),
    ("allowGlobal", "Allow global IP"),
    ("allowManaged", "Allow managed IP"),
    ("allowDNS", "Allow DNS configuration"),
)


def icon_path():
    if getattr(sys, "frozen", False):
        candidate = (
            Path(sys._MEIPASS) / "zerotier_gui" / "assets" / "zerotier-gui.png"
        )
    else:
        candidate = Path(__file__).resolve().parent / "assets" / "zerotier-gui.png"
    if candidate.is_file():
        return candidate
    fallback = "/usr/share/pixmaps/zerotier-gui.png"
    return Path(fallback) if os.path.isfile(fallback) else None


def is_available():
    return QSystemTrayIcon.isSystemTrayAvailable()


class TrayManager(QObject):
    def __init__(self, controller, app, window, parent=None):
        super().__init__(parent)
        self.controller = controller
        self.app = app
        self.window = window
        self._menu = None

        self.icon = QSystemTrayIcon(self)
        path = icon_path()
        if path is not None:
            self.icon.setIcon(QIcon(str(path)))
        self.icon.setToolTip("ZeroTier GUI")
        self.icon.activated.connect(self._on_activated)

        controller.networksChanged.connect(self.rebuild)
        controller.serviceChanged.connect(self.rebuild)
        controller.peersChanged.connect(self.rebuild)
        controller.appearanceChanged.connect(self.rebuild)
        controller.notificationRequested.connect(self._on_notification)
        controller.accessRequested.connect(self._on_access_requested)

        self.rebuild()
        self.icon.show()

    # -- window helpers -------------------------------------------------
    def show_window(self):
        self.window.show()
        self.window.raise_()
        self.window.requestActivate()

    def hide_window(self):
        self.window.hide()

    def toggle_window(self):
        if self.window.isVisible():
            self.hide_window()
        else:
            self.show_window()

    def quit(self):
        self.window.setProperty("forceQuit", True)
        self.app.quit()

    # -- notifications --------------------------------------------------
    def _on_notification(self, title, message):
        if not self.window.isVisible():
            self.icon.showMessage(
                title, message, QSystemTrayIcon.Information, 4000
            )

    def _on_access_requested(self):
        self.show_window()

    def _on_activated(self, reason):
        if reason in (QSystemTrayIcon.Trigger, QSystemTrayIcon.DoubleClick):
            self.toggle_window()

    # -- menu -----------------------------------------------------------
    def rebuild(self):
        menu = QMenu()
        address = self.controller.aboutInfo.get("address") or "unknown"
        node = menu.addAction(f"Node {address}")
        node.setEnabled(False)
        menu.addSeparator()

        open_action = menu.addAction("Open ZeroTier GUI")
        open_action.triggered.connect(self.show_window)

        join = menu.addAction("Join network…")
        join.triggered.connect(self._join_network)

        networks_menu = menu.addMenu("Networks")
        networks = self.controller.networks
        if networks:
            for network in networks:
                self._add_network(networks_menu, network)
        else:
            empty = networks_menu.addAction("No networks joined")
            empty.setEnabled(False)

        peers = menu.addAction("Node peers…")
        peers.triggered.connect(self._show_peers)

        about = menu.addAction("About…")
        about.triggered.connect(self._show_about)

        menu.addSeparator()

        startup = menu.addAction("Start at login")
        startup.setCheckable(True)
        startup.setChecked(autostart.is_enabled())
        startup.triggered.connect(self._toggle_startup)

        keep = menu.addAction("Keep running in tray")
        keep.setCheckable(True)
        keep.setChecked(bool(self.controller.keepInTray))
        keep.triggered.connect(self.controller.setKeepInTrayPreference)

        menu.addSeparator()

        quit_action = menu.addAction("Quit ZeroTier GUI")
        quit_action.triggered.connect(self.quit)

        previous = self._menu
        self._menu = menu
        self.icon.setContextMenu(menu)
        if previous is not None:
            previous.deleteLater()

    def _add_network(self, parent_menu, network):
        submenu = parent_menu.addMenu(f"{network['name']} — {network['statusLabel']}")
        addresses = network.get("addresses") or []
        if addresses:
            for address in addresses:
                action = submenu.addAction(address)
                action.triggered.connect(
                    lambda checked=False, value=address: self.controller.copyToClipboard(value)
                )
        else:
            empty = submenu.addAction("No addresses")
            empty.setEnabled(False)
        submenu.addSeparator()
        for key, label in NETWORK_OPTIONS:
            action = submenu.addAction(label)
            action.setCheckable(True)
            action.setChecked(bool(network.get(key)))
            action.triggered.connect(
                lambda checked, nid=network["id"], opt=key: self.controller.setNetworkOption(
                    nid, opt, checked
                )
            )
        submenu.addSeparator()
        toggle = submenu.addAction("Toggle interface")
        toggle.triggered.connect(
            lambda checked=False, nid=network["id"]: self.controller.toggleInterface(nid)
        )
        leave = submenu.addAction("Leave network")
        leave.triggered.connect(
            lambda checked=False, nid=network["id"]: self.controller.leaveNetwork(nid)
        )

    # -- menu actions ---------------------------------------------------
    def _join_network(self):
        self.show_window()
        self.controller.openJoinDialog()

    def _show_peers(self):
        self.show_window()
        self.controller.openPeersDialog()

    def _show_about(self):
        self.show_window()
        self.controller.openAboutDialog()

    def _toggle_startup(self, checked):
        autostart.set_enabled(checked)
