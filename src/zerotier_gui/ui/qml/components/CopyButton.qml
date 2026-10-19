import QtQuick
import QtQuick.Controls

Button {
    id: control

    property var colors
    property string value: ""
    property color maskColor: colors ? colors.surface : "transparent"

    implicitWidth: 26
    implicitHeight: 26
    padding: 0
    hoverEnabled: true

    ToolTip.visible: hovered
    ToolTip.text: "Copy"

    background: Rectangle {
        radius: 7
        color: control.hovered || control.pressed ? control.colors.surfaceAlt : "transparent"
        border.width: control.hovered ? 1 : 0
        border.color: control.colors.border
        Behavior on color { ColorAnimation { duration: 110 } }
    }

    contentItem: Item {
        implicitWidth: 18
        implicitHeight: 18

        Rectangle {
            x: 0
            y: 0
            width: 11
            height: 13
            radius: 3
            color: "transparent"
            border.width: 1.4
            border.color: control.hovered ? control.colors.text : control.colors.muted
        }
        Rectangle {
            x: 6
            y: 5
            width: 11
            height: 13
            radius: 3
            color: control.maskColor
            border.width: 1.4
            border.color: control.hovered ? control.colors.text : control.colors.muted
        }
    }

    onClicked: backend.copyToClipboard(value)
}
