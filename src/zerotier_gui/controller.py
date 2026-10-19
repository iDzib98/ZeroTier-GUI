"""Qt/QML bridge. Exposes application state and actions without UI details."""

from PySide6.QtCore import Property, QObject, Signal, Slot
from PySide6.QtGui import QGuiApplication

from . import __version__
from .history import NetworkHistory
from .preferences import Preferences
from .service import ZeroTierError, ZeroTierService
from .theme import palette_for


class MainController(QObject):
    networksChanged = Signal()
    peersChanged = Signal()
    peerPathsChanged = Signal()
    serviceChanged = Signal()
    selectionChanged = Signal()
    historyChanged = Signal()
    filterChanged = Signal()
    appearanceChanged = Signal()
    notificationRequested = Signal(str, str)
    accessRequested = Signal()
    hideWindow = Signal()
    quitWindow = Signal()
    askClose = Signal()
    joinDialogRequested = Signal()
    peersDialogRequested = Signal()
    aboutDialogRequested = Signal()

    def __init__(self, theme_name="light", start_hidden=False, parent=None):
        super().__init__(parent)
        self.service = ZeroTierService()
        self.history = NetworkHistory()
        self.preferences = Preferences()
        self._start_hidden = start_hidden
        self._tray_available = False
        self._theme_name = theme_name
        self._colors = palette_for(theme_name)
        self._networks = []
        self._peers = []
        self._peer_paths = []
        self._service_status = "unknown"
        self._selected_network_id = ""
        self._selected_peer_id = ""
        self._search_text = ""
        self._about = {}

    @Property("QVariantList", notify=networksChanged)
    def networks(self):
        return self._networks

    @Property("QVariantList", notify=networksChanged)
    def filteredNetworks(self):
        query = self._search_text.strip().lower()
        if not query:
            return self._networks
        return [
            network
            for network in self._networks
            if query in network["name"].lower()
            or query in network["id"].lower()
            or query in " ".join(network["addresses"]).lower()
        ]

    @Property("QVariantList", notify=peersChanged)
    def peers(self):
        return self._peers

    @Property("QVariantList", notify=peerPathsChanged)
    def peerPaths(self):
        return self._peer_paths

    @Property("QVariantMap", notify=selectionChanged)
    def selectedNetwork(self):
        for network in self._networks:
            if network["id"] == self._selected_network_id:
                return network
        return {}

    @Property(str, notify=selectionChanged)
    def selectedNetworkId(self):
        return self._selected_network_id

    @Property(str, notify=serviceChanged)
    def serviceStatus(self):
        return self._service_status

    @Property(bool, notify=serviceChanged)
    def serviceRunning(self):
        return self._service_status == "active"

    @Property(str, notify=appearanceChanged)
    def themeName(self):
        return self._theme_name

    @Property(str, notify=appearanceChanged)
    def appVersion(self):
        return __version__

    @Property("QVariantMap", notify=appearanceChanged)
    def colors(self):
        return self._colors

    @Property("QVariantList", notify=historyChanged)
    def networkHistory(self):
        return self.history.list()

    @Property("QVariantMap", notify=peersChanged)
    def aboutInfo(self):
        return self._about

    @Property(int, notify=networksChanged)
    def networkCount(self):
        return len(self._networks)

    @Property(bool, constant=True)
    def startHidden(self):
        return self._start_hidden

    @Property(bool, notify=appearanceChanged)
    def trayAvailable(self):
        return self._tray_available

    @Property(bool, notify=appearanceChanged)
    def keepInTray(self):
        return bool(self.preferences.get("keep_in_tray", True))

    @Slot(str)
    def setSearchText(self, text):
        self._search_text = text
        self.networksChanged.emit()

    @Slot(str)
    def selectNetwork(self, network_id):
        self._selected_network_id = str(network_id)
        self.selectionChanged.emit()

    @Slot(str)
    def refreshNetworks(self):
        try:
            self._networks = self.service.networks()
            joined = {network["id"]: network["name"] for network in self._networks}
            for network_id, name in joined.items():
                if network_id in self.history.entries:
                    self.history.entries[network_id]["name"] = name
            self.history.save()
            if self._selected_network_id not in joined:
                self._selected_network_id = ""
            self.networksChanged.emit()
            self.selectionChanged.emit()
            self.historyChanged.emit()
        except ZeroTierError as error:
            if error.returncode == 2 or "authtoken" in str(error).lower():
                self.accessRequested.emit()
            else:
                self.notificationRequested.emit("ZeroTier", str(error))

    def set_tray_available(self, available):
        self._tray_available = bool(available)
        self.appearanceChanged.emit()

    @Slot()
    def refreshAll(self):
        self.refreshNetworks()
        self.refreshService()
        self.refreshAbout()

    @Slot()
    def refreshService(self):
        try:
            self._service_status = self.service.service_status()
        except ZeroTierError as error:
            self._service_status = "unavailable"
            self.notificationRequested.emit("Service status", str(error))
        self.serviceChanged.emit()

    @Slot()
    def toggleService(self):
        try:
            self.service.set_service_running(not self.serviceRunning)
            self.refreshService()
            self.refreshNetworks()
        except ZeroTierError as error:
            self.notificationRequested.emit("Could not change service", str(error))

    @Slot(str, result=bool)
    def joinNetwork(self, network_id):
        network_id = network_id.strip()
        if not network_id:
            self.notificationRequested.emit("Join network", "Enter a network ID.")
            return False
        try:
            self.service.join_network(network_id)
            name = next(
                (item["name"] for item in self.service.networks() if item["id"] == network_id),
                "Unknown network",
            )
            self.history.add(network_id, name)
            self.notificationRequested.emit("Joined network", f"Joined {name}.")
            self.refreshNetworks()
            self.historyChanged.emit()
            return True
        except ZeroTierError as error:
            self.notificationRequested.emit("Could not join network", str(error))
            return False

    @Slot(str)
    def leaveNetwork(self, network_id):
        try:
            self.service.leave_network(network_id)
            self.notificationRequested.emit("Network left", "The network was left.")
            self.refreshNetworks()
        except ZeroTierError as error:
            self.notificationRequested.emit("Could not leave network", str(error))

    @Slot(str)
    def toggleInterface(self, network_id):
        network = next(
            (item for item in self._networks if item["id"] == network_id), None
        )
        if not network:
            return
        try:
            self.service.toggle_interface(
                network["interface"], network["interfaceState"].lower() != "down"
            )
            self.refreshNetworks()
        except ZeroTierError as error:
            self.notificationRequested.emit("Could not toggle interface", str(error))

    @Slot(str, str, bool)
    def setNetworkOption(self, network_id, option, enabled):
        if option not in ("allowDefault", "allowGlobal", "allowManaged", "allowDNS"):
            return
        try:
            self.service.set_network_option(network_id, option, enabled)
            self.refreshNetworks()
        except ZeroTierError as error:
            self.notificationRequested.emit("Network setting failed", str(error))

    @Slot()
    def refreshPeers(self):
        try:
            self._peers = self.service.peers()
            self.peersChanged.emit()
        except ZeroTierError as error:
            self.notificationRequested.emit("Could not load peers", str(error))

    @Slot(str)
    def showPeerPaths(self, peer_id):
        peer = next((item for item in self._peers if item["address"] == peer_id), None)
        self._selected_peer_id = str(peer_id)
        self._peer_paths = peer["paths"] if peer else []
        self.peerPathsChanged.emit()

    @Slot(str)
    def showNetworkInfo(self, network_id):
        self.selectNetwork(network_id)

    @Slot()
    def refreshAbout(self):
        try:
            self._about = self.service.status()
            self.peersChanged.emit()
        except ZeroTierError as error:
            self.notificationRequested.emit("ZeroTier status", str(error))

    @Slot(str)
    def copyToClipboard(self, text):
        QGuiApplication.clipboard().setText(str(text))

    @Slot()
    def requestClose(self):
        preference = self.preferences.get("keep_in_tray", None)
        if preference is True:
            self.hideWindow.emit()
        elif preference is False:
            self.quitWindow.emit()
        else:
            self.askClose.emit()

    @Slot(bool, bool)
    def setKeepInTray(self, keep, remember):
        if remember:
            self.preferences.set("keep_in_tray", bool(keep))
            self.appearanceChanged.emit()
        if keep:
            self.hideWindow.emit()
        else:
            self.quitWindow.emit()

    @Slot(bool)
    def setKeepInTrayPreference(self, keep):
        self.preferences.set("keep_in_tray", bool(keep))
        self.appearanceChanged.emit()

    @Slot()
    def openJoinDialog(self):
        self.joinDialogRequested.emit()

    @Slot()
    def openPeersDialog(self):
        self.peersDialogRequested.emit()

    @Slot()
    def openAboutDialog(self):
        self.aboutDialogRequested.emit()

    @Slot(str, str)
    def removeHistory(self, network_id, _unused=""):
        self.history.remove(network_id)
        self.historyChanged.emit()

    @Slot()
    def setupAccess(self):
        try:
            self.service.ensure_user_access()
            self.notificationRequested.emit(
                "Access enabled",
                "Your account can now manage ZeroTier. Refreshing networks.",
            )
            self.refreshAll()
        except (ZeroTierError, OSError) as error:
            self.notificationRequested.emit("Could not grant access", str(error))
