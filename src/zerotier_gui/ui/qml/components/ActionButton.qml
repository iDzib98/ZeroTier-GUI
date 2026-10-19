import QtQuick
import QtQuick.Controls

Button {
    id: control

    property var colors: backend.colors
    property bool primary: false
    property bool destructive: false
    property bool compact: false

    implicitHeight: compact ? 34 : 40
    implicitWidth: Math.max(contentItem.implicitWidth + (compact ? 26 : 34), compact ? 72 : 88)
    padding: compact ? 9 : 13
    hoverEnabled: true

    background: Rectangle {
        radius: 10
        color: !control.enabled ? control.colors.surfaceAlt : control.destructive
              ? (control.hovered ? control.colors.danger : control.colors.dangerSoft)
              : control.primary
                ? (control.hovered ? control.colors.accentHover : control.colors.accent)
                : (control.hovered ? control.colors.surfaceAlt : control.colors.surface)
        border.width: control.enabled && (control.primary || control.destructive) ? 0 : 1
        border.color: control.colors.border
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    contentItem: Text {
        text: control.text
        color: !control.enabled
               ? control.colors.muted
               : control.destructive && control.hovered
               ? "#ffffff"
               : control.destructive
                 ? control.colors.danger
                 : control.primary
                   ? "#ffffff"
                   : control.colors.text
        font.pixelSize: compact ? 12 : 13
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideNone
    }
}
