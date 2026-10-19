import QtQuick

Rectangle {
    id: chip

    property string text: "Okay"
    property string tone: "success"
    property var colors: backend.colors

    readonly property color chipColor: tone === "success" ? colors.success
        : tone === "danger" ? colors.danger
        : tone === "accent" ? colors.accent
        : colors.muted
    readonly property color chipFill: tone === "success" ? colors.successSoft
        : tone === "danger" ? colors.dangerSoft
        : tone === "accent" ? colors.accentSoft
        : colors.surfaceAlt

    implicitWidth: chipLabel.implicitWidth + 28
    implicitHeight: 27
    radius: height / 2
    color: chipFill

    Row {
        anchors.centerIn: parent
        spacing: 7
        Rectangle {
            width: 14
            height: 14
            radius: 7
            color: chip.chipColor
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.centerIn: parent
                text: chip.tone === "success" ? "✓" : chip.tone === "danger" ? "!" : "•"
                color: chip.chipFill
                font.pixelSize: 10
                font.bold: true
            }
        }
        Text {
            id: chipLabel
            text: chip.text
            color: chip.chipColor
            font.pixelSize: 12
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
