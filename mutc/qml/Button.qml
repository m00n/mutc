import Qt 4.7

Rectangle {
    id: button

    signal buttonClicked
    signal buttonHovered(bool hovered)

    property string button_text
    property string image: ""

    property color default_color: "#00000000"
    property bool disabled

    color: {
        /*
        if (mouse_area.containsMouse) {
            "steelblue"
        } else if (mouse_area.pressedButtons == Qt.LeftButton && mouse_area.containsMouse) {
            Qt.lighter("steelblue", 1.5)
        } else {
            default_color
        }*/
        if (disabled) {
            default_color
        } else if (mouse_area.pressedButtons == Qt.LeftButton && mouse_area.containsMouse) {
            Qt.lighter("steelblue", 1.5)
        } else if (mouse_area.containsMouse) {
            "steelblue"
        } else {
            default_color
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

        onHoveredChanged: {
            button.buttonHovered(containsMouse)
        }

        onClicked: {
            if (!disabled)
                parent.buttonClicked()
        }
    }
}
