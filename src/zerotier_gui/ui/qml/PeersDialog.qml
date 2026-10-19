import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Dialog {
    id: dialog
    property var backend
    property var colors: backend.colors
    signal showPaths(string peerId)

    modal: true
    title: "Node peers"
    width: Math.min(820, parent ? parent.width - 32 : 820)
    height: Math.min(560, parent ? parent.height - 32 : 560)
    anchors.centerIn: Overlay.overlay
    padding: 20
    background: Rectangle {
        radius: 18
        color: dialog.colors.surface
        border.color: dialog.colors.border
        border.width: 1
    }
    header: DialogHeader {
        colors: dialog.colors
        sidePadding: 20
        title: dialog.title
        subtitle: "All peers known to the local ZeroTier service. This list is not filtered by the selected network."
        ActionButton {
            text: "Refresh"
            compact: true
            colors: dialog.colors
            onClicked: dialog.backend.refreshPeers()
        }
    }
    contentItem: ColumnLayout {
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            Label { Layout.fillWidth: true; text: "Peer address"; color: dialog.colors.muted; font.bold: true }
            Label { Layout.preferredWidth: 130; text: "Version"; color: dialog.colors.muted; font.bold: true }
            Label { Layout.preferredWidth: 100; text: "Role"; color: dialog.colors.muted; font.bold: true }
            Label { Layout.preferredWidth: 80; text: "Latency"; color: dialog.colors.muted; font.bold: true }
            Label { Layout.preferredWidth: 65; text: "Paths"; color: dialog.colors.muted; font.bold: true }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: dialog.colors.border }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 3
            model: dialog.backend.peers
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 48
                radius: 8
                color: peerMouse.containsMouse ? dialog.colors.surfaceAlt : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6
                        SelectableLabel {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            Layout.alignment: Qt.AlignVCenter
                            colors: dialog.colors
                            mono: true
                            text: modelData.address
                        }
                        CopyButton {
                            Layout.alignment: Qt.AlignVCenter
                            colors: dialog.colors
                            value: modelData.address
                        }
                    }
                    SelectableLabel { Layout.preferredWidth: 130; Layout.alignment: Qt.AlignVCenter; colors: dialog.colors; mono: true; text: modelData.version; textColor: dialog.colors.muted }
                    Label { Layout.preferredWidth: 100; text: modelData.role; color: dialog.colors.muted }
                    SelectableLabel { Layout.preferredWidth: 80; Layout.alignment: Qt.AlignVCenter; colors: dialog.colors; mono: true; text: modelData.latency >= 0 ? modelData.latency + " ms" : "-"; textColor: dialog.colors.muted }
                    ActionButton {
                        text: "View"
                        compact: true
                        colors: dialog.colors
                        onClicked: dialog.showPaths(modelData.address)
                    }
                }
                MouseArea { id: peerMouse; anchors.fill: parent; z: -1; hoverEnabled: true }
            }
        }
        Label {
            visible: dialog.backend.peers.length === 0
            Layout.fillWidth: true
            text: "No peers are currently connected."
            color: dialog.colors.muted
            horizontalAlignment: Text.AlignHCenter
            padding: 18
        }
    }
}
