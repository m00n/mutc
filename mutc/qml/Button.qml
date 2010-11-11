import Qt 4.7

Rectangle {
    id: button

    signal buttonClicked

    property string button_text
    property string image: ""

    color: {
        if (mouse_area.pressedButtons == Qt.LeftButton) {
            Qt.lighter("steelblue", 1.5)
        } else if (mouse_area.containsMouse) {
            "steelblue"
            //"red"
        } else {
            "#00000000"
        }
    }

    Behavior on color {
        ColorAnimation { duration: 250 }
    }

    border.color: "white"
    border.width: 2

    Text {
        text: button_text
        anchors.centerIn: parent
        color: "white"
    }

    MouseArea {
        id: mouse_area
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            parent.buttonClicked()
        }
    }
}
