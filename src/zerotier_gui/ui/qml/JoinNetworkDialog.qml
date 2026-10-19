import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Dialog {
    id: dialog
    property var backend
    property var colors: backend.colors

    modal: true
    title: "Join a network"
    width: Math.min(520, parent ? parent.width - 32 : 520)
    anchors.centerIn: Overlay.overlay
    padding: 22

    background: Rectangle {
        radius: 18
        color: dialog.colors.surface
        border.color: dialog.colors.border
        border.width: 1
    }
    header: DialogHeader {
        colors: dialog.colors
        title: dialog.title
        subtitle: "Enter a Network ID or choose one from your history."
    }

    contentItem: ColumnLayout {
        spacing: 12
        TextField {
            id: networkId
            Layout.fillWidth: true
            placeholderText: "16-character Network ID"
            selectByMouse: true
            color: dialog.colors.text
            placeholderTextColor: dialog.colors.muted
            font.pixelSize: 14
            background: Rectangle {
                radius: 10
                color: dialog.colors.input
                border.width: networkId.activeFocus ? 2 : 1
                border.color: networkId.activeFocus ? dialog.colors.accent : dialog.colors.border
            }
            onAccepted: joinButton.clicked()
        }

        Label {
            text: "Recent networks"
            color: dialog.colors.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
            visible: historyList.count > 0
        }

        ListView {
            id: historyList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 210)
            clip: true
            model: dialog.backend.networkHistory
            spacing: 5
            delegate: Rectangle {
                required property var modelData
                width: historyList.width
                height: 54
                radius: 10
                color: rowMouse.containsMouse ? dialog.colors.surfaceAlt : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Label {
                            text: modelData.name
                            color: dialog.colors.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Label {
                            text: modelData.id
                            color: dialog.colors.muted
                            font.pixelSize: 11
                            font.family: "monospace"
                        }
                    }
                    ActionButton {
                        text: "Use"
                        compact: true
                        colors: dialog.colors
                        onClicked: networkId.text = modelData.id
                    }
                    ActionButton {
                        text: "Remove"
                        compact: true
                        colors: dialog.colors
                        onClicked: dialog.backend.removeHistory(modelData.id)
                    }
                }
                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    onClicked: networkId.text = modelData.id
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            ActionButton {
                text: "Cancel"
                colors: dialog.colors
                onClicked: dialog.reject()
            }
            ActionButton {
                id: joinButton
                text: "Join network"
                primary: true
                colors: dialog.colors
                enabled: networkId.text.trim().length > 0
                onClicked: {
                    if (dialog.backend.joinNetwork(networkId.text))
                        dialog.accept()
                }
            }
        }
    }
}
