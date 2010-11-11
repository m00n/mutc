import Qt 4.7

Rectangle {
    width: 320
    height: 90

    signal dialogAccepted

    property bool accepted: false
    property string value: ""

    id: input_dialog

    color: "#323436"

    property alias text: prompt_text.text
    border {
        width: 1
        color: "white"
    }

    Text {
        id: prompt_text
        text: "Enter value"
        color: "white"
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 5
        }
        height: 22
        horizontalAlignment: Text.AlignHCenter
    }

    Rectangle {
        id: input_border
        color: "#00000000"
        border {
            width: 1
            color: "white"
        }
        height: 22
        anchors {
            top: prompt_text.bottom
            left: parent.left
            right: parent.right
            margins: 5
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.margins: 2
            horizontalAlignment: Text.AlignHCenter
            color: "white"
            focus: true
            Keys.onPressed: {
                if (event.key == Qt.Key_Return) {
                    accept()
                }
            }
        }
    }

    Button {
        id: ok_button
        button_text: "ok"
        anchors {
            top: input_border.bottom
            right: parent.right
            topMargin: 10
            rightMargin: 5
        }
        width: parent.width / 3
        height: 22

        onButtonClicked: {
            accept()
        }
    }
    Button {
        button_text: "cancel"
        anchors {
            top: input_border.bottom
            right: ok_button.left
            topMargin: 10
            rightMargin: 5
        }
        width: parent.width / 3
        height: 22

        onButtonClicked: {
            input_dialog.state = "hidden"
        }
    }

    states: [
        State {
            name: "hidden"
            PropertyChanges {
                target: input_dialog
                opacity: 0
            }
        },
        State {
            name: "visible"
            PropertyChanges {
                target: input_dialog
                opacity: 1
            }
            PropertyChanges {
                target: input
                focus: true
            }
            PropertyChanges {
                target: input
                text: ""
            }
        }

    ]

    function accept() {
        value = input.text
        accepted = true
        state = "hidden"
        dialogAccepted()
    }

    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }
}
