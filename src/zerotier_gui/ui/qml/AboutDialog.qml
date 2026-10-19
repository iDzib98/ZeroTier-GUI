import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Dialog {
    id: dialog
    property var backend
    property var colors: backend.colors

    modal: true
    title: "About ZeroTier GUI"
    width: 430
    anchors.centerIn: Overlay.overlay
    padding: 22
    onOpened: backend.refreshAbout()
    background: Rectangle {
        radius: 18
        color: dialog.colors.surface
        border.color: dialog.colors.border
        border.width: 1
    }
    header: DialogHeader {
        colors: dialog.colors
        title: dialog.title
        subtitle: "Manage ZeroTier networks on this device."
    }
    contentItem: ColumnLayout {
        spacing: 11
        Rectangle { Layout.fillWidth: true; height: 1; color: dialog.colors.border }
        Repeater {
            model: [
                { label: "Node address", value: dialog.backend.aboutInfo.address || "-" },
                { label: "ZeroTier version", value: dialog.backend.aboutInfo.version || "-" },
                { label: "GUI version", value: dialog.backend.appVersion },
                { label: "Node status", value: dialog.backend.aboutInfo.status || "-" }
            ]
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Label { Layout.preferredWidth: 120; text: modelData.label; color: dialog.colors.muted; font.pixelSize: 12 }
                CopyableValue {
                    Layout.fillWidth: true
                    colors: dialog.colors
                    value: modelData.value
                }
            }
        }
    }
}
