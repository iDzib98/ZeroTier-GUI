import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property var colors
    property string value: ""
    property bool wrap: false

    spacing: 6

    SelectableLabel {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.alignment: Qt.AlignVCenter
        colors: root.colors
        mono: true
        wrap: root.wrap
        text: root.value
    }

    CopyButton {
        Layout.alignment: Qt.AlignVCenter
        colors: root.colors
        value: root.value
        visible: root.value.length > 0
    }
}
