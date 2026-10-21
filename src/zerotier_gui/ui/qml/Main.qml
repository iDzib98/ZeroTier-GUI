import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

ApplicationWindow {
    id: window

    property var controller: backend
    property var colors: backend.colors
    property bool compact: width < 880
    property bool startHidden: backend.startHidden
    property bool forceQuit: false
    property string pendingLeaveId: ""
    property string pendingLeaveName: ""

    visible: !window.startHidden
    title: "ZeroTier Control Center"
    width: 1120
    height: 760
    minimumWidth: 740
    minimumHeight: 560
    color: colors.background

    Component.onCompleted: backend.refreshAll()

    onClosing: function (close) {
        if (!window.forceQuit && backend.trayAvailable) {
            close.accepted = false
            backend.requestClose()
        }
    }

    background: Rectangle { color: window.colors.background }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: window.compact ? 18 : 30
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                width: 48
                height: 48
                radius: 13
                color: window.colors.accent
                Text {
                    anchors.centerIn: parent
                    text: "ZT"
                    color: window.colors.background
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
            }

            ColumnLayout {
                spacing: 2
                Label {
                    text: "Networks"
                    color: window.colors.text
                    font.pixelSize: window.compact ? 22 : 26
                    font.weight: Font.DemiBold
                }
                Label {
                    text: "Manage your ZeroTier connections"
                    color: window.colors.muted
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredHeight: 52
                Layout.preferredWidth: serviceRow.implicitWidth + 26
                radius: 14
                color: window.colors.surface
                border.color: window.colors.border
                RowLayout {
                    id: serviceRow
                    anchors.centerIn: parent
                    spacing: 10
                    StatusChip {
                        text: backend.serviceRunning ? "Service running" : "Service " + backend.serviceStatus
                        tone: backend.serviceRunning ? "success" : "neutral"
                        colors: window.colors
                    }
                    ActionButton {
                        text: backend.serviceRunning ? "Stop" : "Start"
                        compact: true
                        colors: window.colors
                        enabled: backend.zeroTierInstalled
                        onClicked: backend.toggleService()
                    }
                }
            }
        }

        Rectangle {
            id: installBanner
            objectName: "installBanner"
            visible: !backend.zeroTierInstalled
            Layout.fillWidth: true
            implicitHeight: installBannerLayout.implicitHeight + 24
            radius: 12
            color: window.colors.dangerSoft
            border.color: window.colors.danger
            border.width: 1

            RowLayout {
                id: installBannerLayout
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                Rectangle {
                    width: 34
                    height: 34
                    radius: 9
                    color: window.colors.danger
                    Text {
                        anchors.centerIn: parent
                        text: "!"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 18
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        text: backend.installing ? "Installing ZeroTier…" : "ZeroTier is not installed"
                        color: window.colors.text
                        font.weight: Font.DemiBold
                        font.pixelSize: 14
                    }
                    Label {
                        Layout.fillWidth: true
                        text: "Install the ZeroTier service to join and manage networks."
                        color: window.colors.muted
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }
                ActionButton {
                    text: "Installation guide"
                    colors: window.colors
                    onClicked: Qt.openUrlExternally(backend.downloadUrl)
                }
                ActionButton {
                    text: backend.installing ? "Installing…" : "Install ZeroTier"
                    primary: true
                    colors: window.colors
                    enabled: !backend.installing
                    onClicked: installDialog.open()
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 10
            ActionButton {
                text: "＋  Join network"
                primary: true
                colors: window.colors
                enabled: backend.zeroTierInstalled
                onClicked: joinDialog.open()
            }
            ActionButton {
                text: "Refresh"
                colors: window.colors
                onClicked: backend.refreshNetworks()
            }
            ActionButton {
                text: "Node peers"
                colors: window.colors
                onClicked: {
                    backend.refreshPeers()
                    peersDialog.open()
                }
            }
            ActionButton {
                text: "About"
                colors: window.colors
                onClicked: aboutDialog.open()
            }
            ActionButton {
                text: "Open Central ↗"
                colors: window.colors
                onClicked: Qt.openUrlExternally("https://central.zerotier.com/")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 18
            color: window.colors.surface
            border.color: window.colors.border
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: window.compact ? 14 : 22
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 3
                        Label {
                            text: "Your networks"
                            color: window.colors.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                        Label {
                            text: "Joined virtual networks and their connection state"
                            color: window.colors.muted
                            font.pixelSize: 12
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StatusChip {
                        text: backend.networks.length + (backend.networks.length === 1 ? " network" : " networks")
                        tone: "accent"
                        colors: window.colors
                    }
                }

                TextField {
                    id: networkSearch
                    Layout.fillWidth: true
                    Layout.maximumWidth: 520
                    placeholderText: "Search by name, Network ID or address"
                    color: window.colors.text
                    placeholderTextColor: window.colors.muted
                    selectByMouse: true
                    onTextChanged: backend.setSearchText(text)
                    background: Rectangle {
                        radius: 10
                        color: window.colors.input
                        border.width: networkSearch.activeFocus ? 2 : 1
                        border.color: networkSearch.activeFocus ? window.colors.accent : window.colors.border
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 42
                    radius: 9
                    color: window.colors.surfaceAlt
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 15
                        anchors.rightMargin: 15
                        spacing: 14
                        Label { Layout.minimumWidth: 230; Layout.preferredWidth: 230; Layout.maximumWidth: 230; text: "Network"; color: window.colors.muted; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Label { Layout.fillWidth: true; text: "Assigned addresses"; color: window.colors.muted; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignLeft; visible: !window.compact }
                        Label { Layout.preferredWidth: 142; text: "Status"; color: window.colors.muted; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter }
                        Label { Layout.preferredWidth: 92; text: "Actions"; color: window.colors.muted; font.pixelSize: 12; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignRight }
                    }
                }

                ListView {
                    id: networkList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 5
                    model: backend.filteredNetworks
                    ScrollBar.vertical: ScrollBar { active: true }

                    delegate: Rectangle {
                        required property var modelData
                        width: networkList.width
                        height: 72
                        radius: 11
                        color: backend.selectedNetworkId === modelData.id
                               ? window.colors.selection
                               : (networkMouse.containsMouse ? window.colors.surfaceAlt : "transparent")
                        border.width: backend.selectedNetworkId === modelData.id ? 1 : 0
                        border.color: window.colors.border

                        TapHandler {
                            onTapped: backend.selectNetwork(modelData.id)
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            spacing: 14
                            ColumnLayout {
                                Layout.minimumWidth: 230
                                Layout.preferredWidth: 230
                                Layout.maximumWidth: 230
                                spacing: 4
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: window.colors.text
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                SelectableLabel {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    colors: window.colors
                                    textColor: window.colors.muted
                                    mono: true
                                    text: modelData.id
                                }
                            }
                            Item {
                                id: addressCell
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.minimumWidth: 240
                                Layout.alignment: Qt.AlignVCenter
                                visible: !window.compact
                                implicitHeight: addressLabel.implicitHeight
                                Label {
                                    id: addressLabel
                                    anchors.fill: parent
                                    text: modelData.addresses.length ? modelData.addresses.join("\n") : "—"
                                    color: window.colors.muted
                                    font.pixelSize: 12
                                    font.family: "monospace"
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                }
                            }
                            StatusChip {
                                Layout.minimumWidth: 142
                                Layout.preferredWidth: 142
                                Layout.maximumWidth: 142
                                text: modelData.statusLabel
                                tone: modelData.statusLabel === "Okay" ? "success"
                                    : modelData.statusLabel === "Interface down" || modelData.statusLabel === "Denied" ? "danger"
                                    : "neutral"
                                colors: window.colors
                            }
                            ActionButton {
                                Layout.preferredWidth: 92
                                text: "Details"
                                compact: true
                                colors: window.colors
                                onClicked: {
                                    backend.selectNetwork(modelData.id)
                                    infoDialog.open()
                                }
                            }
                        }
                        MouseArea {
                            id: networkMouse
                            anchors.fill: parent
                            z: -1
                            hoverEnabled: true
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        visible: networkList.count === 0
                        text: networkSearch.text.length ? "No networks match your search."
                              : (backend.zeroTierInstalled ? "No joined networks yet. Join a network to get started."
                                                           : "ZeroTier is not installed on this computer.")
                        color: window.colors.muted
                        font.pixelSize: 14
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: footerLayout.implicitHeight + 26
            radius: 14
            color: window.colors.surface
            border.color: window.colors.border
            RowLayout {
                id: footerLayout
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 11
                anchors.bottomMargin: 11
                spacing: 10
                SelectableLabel {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    colors: window.colors
                    textColor: backend.selectedNetworkId.length ? window.colors.text : window.colors.muted
                    text: backend.selectedNetworkId.length
                          ? backend.selectedNetwork.name + "  ·  " + backend.selectedNetworkId
                          : "Select a network to view details and actions"
                }
                ActionButton {
                    text: "Leave network"
                    compact: true
                    destructive: true
                    colors: window.colors
                    enabled: backend.selectedNetworkId.length > 0
                    onClicked: {
                        window.pendingLeaveId = backend.selectedNetworkId
                        window.pendingLeaveName = backend.selectedNetwork.name
                        leaveDialog.open()
                    }
                }
                ActionButton {
                    text: "Toggle interface"
                    compact: true
                    colors: window.colors
                    enabled: backend.selectedNetworkId.length > 0
                    onClicked: backend.toggleInterface(backend.selectedNetworkId)
                }
                ActionButton {
                    text: "Network info"
                    compact: true
                    colors: window.colors
                    enabled: backend.selectedNetworkId.length > 0
                    onClicked: infoDialog.open()
                }
            }
        }
    }

    JoinNetworkDialog { id: joinDialog; backend: window.controller }
    PeersDialog {
        id: peersDialog
        backend: window.controller
        onShowPaths: {
            backend.showPeerPaths(peerId)
            pathsDialog.open()
        }
    }
    PeerPathsDialog { id: pathsDialog; backend: window.controller }
    NetworkInfoDialog { id: infoDialog; backend: window.controller }
    AboutDialog { id: aboutDialog; backend: window.controller }

    Dialog {
        id: leaveDialog
        property var colors: window.colors
        modal: true
        title: "Leave network?"
        width: 430
        padding: 22
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.NoButton
        background: Rectangle { radius: 16; color: leaveDialog.colors.surface; border.color: leaveDialog.colors.border }
        header: DialogHeader {
            colors: leaveDialog.colors
            title: "Leave network?"
            subtitle: "This device will be disconnected from “" + window.pendingLeaveName + "”."
        }
        contentItem: ColumnLayout {
            Label {
                text: window.pendingLeaveId
                color: leaveDialog.colors.muted
                font.family: "monospace"
                font.pixelSize: 11
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Item { Layout.fillWidth: true }
                ActionButton { text: "Cancel"; colors: leaveDialog.colors; onClicked: leaveDialog.close() }
                ActionButton {
                    text: "Leave"
                    destructive: true
                    colors: leaveDialog.colors
                    onClicked: {
                        backend.leaveNetwork(window.pendingLeaveId)
                        leaveDialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: messageDialog
        property var colors: window.colors
        property string messageText: ""
        modal: true
        title: "ZeroTier GUI"
        width: 400
        padding: 22
        anchors.centerIn: Overlay.overlay
        background: Rectangle { radius: 16; color: messageDialog.colors.surface; border.color: messageDialog.colors.border }
        header: DialogHeader { colors: messageDialog.colors; title: messageDialog.title }
        contentItem: Label { text: messageDialog.messageText; color: messageDialog.colors.text; wrapMode: Text.WordWrap; width: 340 }
        footer: DialogButtonBox {
            ActionButton { text: "OK"; primary: true; colors: messageDialog.colors; onClicked: messageDialog.accept() }
        }
    }

    Dialog {
        id: accessDialog
        property var colors: window.colors
        modal: true
        title: "Allow ZeroTier access"
        width: 420
        padding: 22
        anchors.centerIn: Overlay.overlay
        background: Rectangle { radius: 16; color: accessDialog.colors.surface; border.color: accessDialog.colors.border }
        header: DialogHeader {
            colors: accessDialog.colors
            title: accessDialog.title
            subtitle: "ZeroTier CLI cannot read its authentication token. Grant access to the zerotier-one group?"
        }
        footer: RowLayout {
            Item { Layout.fillWidth: true }
            ActionButton { text: "Cancel"; colors: accessDialog.colors; onClicked: accessDialog.reject() }
            ActionButton {
                text: "Grant access"
                primary: true
                colors: accessDialog.colors
                onClicked: {
                    accessDialog.close()
                    backend.setupAccess()
                }
            }
        }
    }

    Dialog {
        id: closeDialog
        property var colors: window.colors
        modal: true
        title: "Close ZeroTier GUI"
        width: 440
        padding: 22
        anchors.centerIn: Overlay.overlay
        onOpened: rememberClose.checked = false
        background: Rectangle { radius: 16; color: closeDialog.colors.surface; border.color: closeDialog.colors.border }
        header: DialogHeader {
            colors: closeDialog.colors
            title: "Close ZeroTier GUI"
            subtitle: "Keep ZeroTier running in the tray so you can manage your networks without the window?"
        }
        contentItem: ColumnLayout {
            spacing: 20
            CheckBox {
                id: rememberClose
                Layout.fillWidth: true
                text: "Don't ask again"
                checked: false
                spacing: 8
                indicator: Rectangle {
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 5
                    color: rememberClose.checked ? closeDialog.colors.accent : closeDialog.colors.input
                    border.width: 1
                    border.color: rememberClose.checked ? closeDialog.colors.accent : closeDialog.colors.border
                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.bold: true
                        visible: rememberClose.checked
                    }
                }
                contentItem: Text {
                    text: rememberClose.text
                    color: closeDialog.colors.text
                    font.pixelSize: 13
                    leftPadding: rememberClose.indicator.width + 8
                    verticalAlignment: Text.AlignVCenter
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Item { Layout.fillWidth: true }
                ActionButton {
                    text: "Quit"
                    destructive: true
                    colors: closeDialog.colors
                    onClicked: {
                        closeDialog.close()
                        backend.setKeepInTray(false, rememberClose.checked)
                    }
                }
                ActionButton {
                    text: "Keep in tray"
                    primary: true
                    colors: closeDialog.colors
                    onClicked: {
                        closeDialog.close()
                        backend.setKeepInTray(true, rememberClose.checked)
                    }
                }
            }
        }
    }

    Dialog {
        id: installDialog
        objectName: "installDialog"
        property var colors: window.colors
        modal: true
        title: "Install ZeroTier"
        width: 460
        padding: 22
        anchors.centerIn: Overlay.overlay
        background: Rectangle { radius: 16; color: installDialog.colors.surface; border.color: installDialog.colors.border }
        header: DialogHeader {
            colors: installDialog.colors
            title: "Install ZeroTier"
            subtitle: "Download and run the official installer as administrator?"
        }
        contentItem: ColumnLayout {
            spacing: 12
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: installDialog.colors.text
                font.pixelSize: 13
                text: "This runs the official script from install.zerotier.com as root using your system's authentication prompt. It configures the ZeroTier repository and enables the service."
            }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: installDialog.colors.muted
                font.pixelSize: 11
                text: "An internet connection is required."
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Item { Layout.fillWidth: true }
                ActionButton { text: "Cancel"; colors: installDialog.colors; onClicked: installDialog.close() }
                ActionButton {
                    text: "Install"
                    primary: true
                    colors: installDialog.colors
                    onClicked: {
                        installDialog.close()
                        backend.installZeroTier()
                    }
                }
            }
        }
    }

    Connections {
        target: backend
        function onNotificationRequested(title, message) {
            if (!window.visible)
                return
            messageDialog.title = title
            messageDialog.messageText = message
            messageDialog.open()
        }
        function onAccessRequested() { accessDialog.open() }
        function onHideWindow() { window.hide() }
        function onQuitWindow() {
            window.forceQuit = true
            Qt.quit()
        }
        function onAskClose() { closeDialog.open() }
        function onJoinDialogRequested() { joinDialog.open() }
        function onPeersDialogRequested() { peersDialog.open() }
        function onAboutDialogRequested() { aboutDialog.open() }
        function onInstallDialogRequested() { installDialog.open() }
    }
}
