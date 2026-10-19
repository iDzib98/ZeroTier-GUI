import QtQuick
import QtQuick.Controls

TextEdit {
    id: root

    property var colors
    property bool mono: false
    property bool wrap: false
    property color textColor: colors ? colors.text : "transparent"

    readOnly: true
    selectByMouse: true
    persistentSelection: true
    activeFocusOnPress: true
    wrapMode: wrap ? TextEdit.Wrap : TextEdit.NoWrap
    textFormat: TextEdit.PlainText
    color: textColor
    selectionColor: colors ? colors.accent : "transparent"
    selectedTextColor: "#ffffff"
    font.pixelSize: 12
    font.family: mono ? "monospace" : ""
    clip: true
    leftPadding: 0
    topPadding: 0
    rightPadding: 0
    bottomPadding: 0
    cursorVisible: activeFocus
}
