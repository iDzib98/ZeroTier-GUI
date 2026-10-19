import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Dialog {
    id: dialog
    property var backend
    property var colors: backend.colors

    modal: true
    title: "Peer paths"
    width: Math.min(760, parent ? parent.width - 32 : 760)
    height: Math.min(500, parent ? parent.height - 32 : 500)
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
        subtitle: "Active connection paths for this peer."
    }
    contentItem: ColumnLayout {
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            Label { Layout.preferredWidth: 80; text: "Active"; color: dialog.colors.muted; font.bold: true }
            Label { Layout.fillWidth: true; text: "Address"; color: dialog.colors.muted; font.bold: true }
            Label { Layout.preferredWidth: 80; text: "Preferred"; color: dialog.colors.muted; font.bold: true }
            Label { Layout.preferredWidth: 120; text: "Last receive"; color: dialog.colors.muted; font.bold: true }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: dialog.colors.border }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: dialog.backend.peerPaths
            delegate: RowLayout {
                required property var modelData
                width: ListView.view.width
                height: 40
                Label { Layout.preferredWidth: 80; text: modelData.active ? "Yes" : "No"; color: dialog.colors.text }
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
                SelectableLabel { Layout.preferredWidth: 80; Layout.alignment: Qt.AlignVCenter; colors: dialog.colors; textColor: dialog.colors.muted; text: modelData.preferred ? "Yes" : "No" }
                SelectableLabel { Layout.preferredWidth: 120; Layout.alignment: Qt.AlignVCenter; colors: dialog.colors; mono: true; textColor: dialog.colors.muted; text: modelData.lastReceive }
            }
        }
        Label {
            visible: dialog.backend.peerPaths.length === 0
            Layout.fillWidth: true
            text: "No paths are currently available."
            color: dialog.colors.muted
            horizontalAlignment: Text.AlignHCenter
            padding: 16
        }
    }
}
