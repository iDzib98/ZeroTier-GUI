import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Dialog {
    id: dialog
    property var backend
    property var colors: backend.colors
    property var network: backend.selectedNetwork

    modal: true
    title: "Network details"
    width: Math.min(580, parent ? parent.width - 32 : 580)
    height: Math.min(650, parent ? parent.height - 32 : 650)
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
        subtitle: dialog.network.name || ""
    }

    contentItem: Flickable {
        contentWidth: width
        contentHeight: infoColumn.implicitHeight
        clip: true
        ColumnLayout {
            id: infoColumn
            width: parent.width
            spacing: 9
            Repeater {
                model: [
                    { label: "Network ID", value: dialog.network.id || "-" },
                    { label: "Status", value: dialog.network.statusLabel || "-" },
                    { label: "Interface", value: dialog.network.interface || "-" },
                    { label: "State", value: dialog.network.interfaceState || "-" },
                    { label: "Type", value: dialog.network.type || "-" },
                    { label: "MAC address", value: dialog.network.mac || "-" },
                    { label: "MTU", value: dialog.network.mtu || "-" }
                ]
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Label { Layout.preferredWidth: 125; text: modelData.label; color: dialog.colors.muted; font.pixelSize: 12 }
                    CopyableValue {
                        Layout.fillWidth: true
                        colors: dialog.colors
                        value: modelData.value
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                Label { Layout.preferredWidth: 125; text: "Addresses"; color: dialog.colors.muted; font.pixelSize: 12 }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 3
                    Repeater {
                        model: (dialog.network.addresses && dialog.network.addresses.length) ? dialog.network.addresses : ["-"]
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            SelectableLabel {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.minimumWidth: 0
                                colors: dialog.colors
                                mono: true
                                wrap: true
                                text: modelData
                            }
                            CopyButton {
                                Layout.alignment: Qt.AlignVCenter
                                colors: dialog.colors
                                value: modelData
                                visible: modelData !== "-"
                            }
                        }
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: dialog.colors.border }
            Label { text: "Network permissions"; color: dialog.colors.text; font.weight: Font.DemiBold; font.pixelSize: 14 }
            Repeater {
                model: [
                    { key: "allowDefault", label: "Allow default route" },
                    { key: "allowGlobal", label: "Allow global IP" },
                    { key: "allowManaged", label: "Allow managed IP" },
                    { key: "allowDNS", label: "Allow DNS configuration" }
                ]
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Label { Layout.fillWidth: true; text: modelData.label; color: dialog.colors.text }
                    Switch {
                        checked: Boolean(dialog.network[modelData.key])
                        onToggled: dialog.backend.setNetworkOption(dialog.network.id, modelData.key, checked)
                        indicator: Rectangle {
                            implicitWidth: 40
                            implicitHeight: 23
                            x: parent.leftPadding
                            y: parent.height / 2 - height / 2
                            radius: height / 2
                            color: parent.checked ? dialog.colors.accent : dialog.colors.surfaceAlt
                            border.color: parent.checked ? dialog.colors.accent : dialog.colors.border
                            Rectangle {
                                x: parent.parent.checked ? parent.width - width - 3 : 3
                                y: 3
                                width: 17
                                height: 17
                                radius: 9
                                color: "#ffffff"
                            }
                        }
                    }
                }
            }
        }
    }
}
