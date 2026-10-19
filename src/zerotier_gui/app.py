"""Application entry point and QML engine setup."""

import os
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication

from . import __version__
from .controller import MainController
from .single_instance import SingleInstanceServer, notify_existing
from .theme import detect_theme
from .tray import TrayManager, is_available as tray_available


def qml_directory():
    if getattr(sys, "frozen", False):
        return Path(sys._MEIPASS) / "zerotier_gui" / "ui" / "qml"
    return Path(__file__).resolve().parent / "ui" / "qml"


def main(argv=None):
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    # A dashboard does not need 3D acceleration; software rendering avoids
    # fragile EGL/RHI initialization across AppImage and hybrid-GPU systems.
    os.environ.setdefault("QT_QUICK_BACKEND", "software")

    argv = list(argv if argv is not None else sys.argv)
    start_hidden = "--hidden" in argv
    argv = [argument for argument in argv if argument != "--hidden"]

    app = QApplication(argv)
    app.setApplicationName("ZeroTier GUI")
    app.setApplicationDisplayName("ZeroTier GUI")
    app.setApplicationVersion(__version__)
    app.setOrganizationName("ZeroTier GUI")

    available = tray_available()
    # With a tray icon the app outlives its window; without one, closing the
    # window should exit.
    app.setQuitOnLastWindowClosed(not available)

    if notify_existing("noop" if start_hidden else "show"):
        return 0

    controller = MainController(
        theme_name=detect_theme(app), start_hidden=start_hidden, parent=app
    )
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", controller)
    engine.addImportPath(str(qml_directory()))
    if getattr(sys, "frozen", False):
        engine.addImportPath(str(Path(sys._MEIPASS) / "PySide6" / "Qt" / "qml"))
    else:
        try:
            import PySide6

            qt_qml = Path(PySide6.__file__).resolve().parent / "Qt" / "qml"
            if qt_qml.is_dir():
                engine.addImportPath(str(qt_qml))
        except (ImportError, OSError):
            pass
    engine.load(QUrl.fromLocalFile(str(qml_directory() / "Main.qml")))
    if not engine.rootObjects():
        return 1

    window = engine.rootObjects()[0]
    if start_hidden and not available:
        # No tray to fall back to; do not leave an invisible running app.
        window.show()

    tray = None
    controller.set_tray_available(available)
    if available:
        tray = TrayManager(controller, app, window, parent=app)

    def reveal():
        if tray is not None:
            tray.show_window()
        else:
            window.show()
            window.raise_()
            window.requestActivate()

    server = SingleInstanceServer(parent=app)
    server.activated.connect(reveal)

    app.aboutToQuit.connect(controller.history.save)
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
