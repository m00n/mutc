import QtQuick 1.0

Rectangle {
    color: "#00000000"

    width: 310
    height: 22

    property alias text: text_input.text

    border {
        color: style.darkBorderColor
    }

    TextInput {
        id: text_input

        text: ""
        anchors.fill: parent
        anchors.margins: 4
        color: style.textColor
    }
}
