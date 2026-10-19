"""Single-instance guard built on a local socket.

A second launch asks the running instance to reveal its window instead of
starting another tray icon. The socket lives in the shared application data
directory so it also works across separate Flatpak launches of the same app.
"""

import os

from PySide6.QtCore import QObject, Signal
from PySide6.QtNetwork import QLocalServer, QLocalSocket


def instance_name():
    return f"zerotier-gui-{os.getuid()}"


def notify_existing(message="show", timeout=400):
    socket = QLocalSocket()
    socket.connectToServer(instance_name())
    if not socket.waitForConnected(timeout):
        return False
    socket.write(message.encode("utf-8"))
    socket.flush()
    socket.waitForBytesWritten(timeout)
    socket.disconnectFromServer()
    return True


class SingleInstanceServer(QObject):
    activated = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.server = QLocalServer(self)
        self.server.setSocketOptions(QLocalServer.UserAccessOption)
        QLocalServer.removeServer(instance_name())
        self.server.listen(instance_name())
        self.server.newConnection.connect(self._on_connection)

    def _on_connection(self):
        socket = self.server.nextPendingConnection()
        if socket is None:
            return
        socket.readyRead.connect(lambda: None)
        socket.disconnected.connect(socket.deleteLater)
        self.activated.emit()
