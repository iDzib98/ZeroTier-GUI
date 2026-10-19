import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property var colors
    property int topPadding: 22
    property int sidePadding: 22
    property int bottomPadding: 12

    default property alias actions: actionsRow.data

    implicitHeight: headerRow.implicitHeight + topPadding + bottomPadding

    RowLayout {
        id: headerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.sidePadding
        anchors.rightMargin: root.sidePadding
        anchors.topMargin: root.topPadding
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Label {
                Layout.fillWidth: true
                text: root.title
                color: root.colors.text
                font.pixelSize: 20
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: root.colors.muted
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
        }

        RowLayout {
            id: actionsRow
            Layout.alignment: Qt.AlignTop
            spacing: 8
        }
    }
}
