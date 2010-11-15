import Qt 4.7

Rectangle {
    width: 320
    height: 90

    signal dialogAccepted

    property bool accepted: false
    property string value: ""

    id: dialog

    color: "#323436"

    property alias text: prompt_text.text
    property alias title: title_text

    border {
        width: 1
        color: "white"
    }

    Toolbar {
        id: title_bar

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 1
        }
        height:22

        Text {
            id: title_text
            text: ""
            color: "white"
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Text {
        id: prompt_text
        text: "Enter value"
        color: "white"
        anchors {
            left: parent.left
            right: parent.right
            top: title_bar.top
            margins: 5
        }
        height: 22
        horizontalAlignment: Text.AlignHCenter
    }

    Button {
        id: ok_button
        button_text: "ok"
        anchors {
            bottom: parent.bottom
            right: parent.right
            topMargin: 10
            rightMargin: 5
            bottomMargin: 5
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
            bottom: parent.bottom
            right: ok_button.left
            topMargin: 10
            rightMargin: 5
            bottomMargin: 5
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
                target: dialog
                opacity: 0
            }
        },
        State {
            name: "visible"
            PropertyChanges {
                target: dialog
                opacity: 1
            }
        }
    ]

    function accept() {
        accepted = true
        state = "hidden"
        dialogAccepted()
    }

    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }
}
