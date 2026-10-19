FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

# Build dependencies for the PySide6/QML application and its self-contained
# PyInstaller bundle.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-venv \
        python3-pip \
        libpython3-dev \
        binutils \
        wget \
        ca-certificates \
        file \
        libfuse2 \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/pyinstaller \
    && /opt/pyinstaller/bin/pip install --no-cache-dir --upgrade pip \
        pyinstaller PySide6_Essentials==6.8.2.1

WORKDIR /build

COPY src/zerotier-gui /build/zerotier-gui
COPY src/zerotier_gui /build/zerotier_gui
COPY img/zerotier-gui.png /build/zerotier-gui.png
COPY zerotier-gui.desktop /build/zerotier-gui.desktop
COPY packaging/appimage/AppRun /build/AppRun
COPY packaging/appimage/zerotier-cli /build/zerotier-cli

RUN /opt/pyinstaller/bin/pyinstaller \
        --onefile \
        --windowed \
        --name zerotier-gui \
        --collect-all PySide6 \
        --add-data /build/zerotier_gui/ui/qml:zerotier_gui/ui/qml \
        --add-data /build/zerotier_gui/assets:zerotier_gui/assets \
        --distpath /build/dist \
        --workpath /build/pyinstaller-build \
        --specpath /build/pyinstaller-build \
        /build/zerotier-gui

RUN mkdir -p /build/AppDir/usr/bin \
        /build/AppDir/usr/share/applications \
        /build/AppDir/usr/share/icons/hicolor/256x256/apps \
    && install -m 0755 /build/dist/zerotier-gui /build/AppDir/usr/bin/zerotier-gui \
    && install -m 0755 /build/zerotier-cli /build/AppDir/usr/bin/zerotier-cli \
    && install -m 0755 /build/AppRun /build/AppDir/AppRun \
    && cp /build/zerotier-gui.png /build/AppDir/zerotier-gui.png \
    && cp /build/zerotier-gui.png /build/AppDir/usr/share/icons/hicolor/256x256/apps/zerotier-gui.png \
    && cp /build/zerotier-gui.desktop /build/AppDir/zerotier-gui.desktop

# Fetch appimagetool and extract it (avoids needing FUSE at build time).
RUN wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage \
        -O /usr/local/bin/appimagetool \
    && chmod +x /usr/local/bin/appimagetool \
    && cd /usr/local/bin && ./appimagetool --appimage-extract >/dev/null

ENV ARCH=x86_64
RUN /usr/local/bin/squashfs-root/AppRun --no-appstream /build/AppDir /build/ZeroTier-GUI.AppImage

CMD ["/bin/true"]
