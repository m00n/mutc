import Qt 4.7


Rectangle {
    id: tweet_dialog

    width: 320
    height: 240

    SystemPalette { id: activePalette }

    color: "#323436"

    signal sendClicked

    property int partition: height / 8
    property alias text: tweet_area.text
    property Item edit: tweet_area
    property string in_reply_id
    property string in_reply
    property bool direct_message
    property string direct_message_from

    Rectangle {
        id: status

        width: parent.width
        height: direct_message ? partition : 0

        border.width: 2
        border.color: activePalette.window
        color: "#00000000"

        Text {
            visible: direct_message
            text: "DM " + in_reply
            color: "white"
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                margins: 2
            }
        }

        anchors.top: parent.top
    }

    Rectangle {
        id: tweet_border

        width: parent.width
        height: partition * (direct_message ? 4 : 5)

        border.width: 2
        border.color: activePalette.window
        color: "#00000000"
        TextEdit {
            id: tweet_area
            z: 5
            anchors.fill: parent
            anchors.margins: 5

            color: "white"

            wrapMode: TextEdit.Wrap

            Keys.onReturnPressed: {
                sendClicked()
                tweet_dialog.state = "busy"
            }
        }

        anchors.top: status.bottom
    }

    Item {
        id: thobber_border

        AnimatedImage {
            id: thobber

            source: "thobber.gif"
            playing: false
            visible: false

            height: 11
            width: 50
            //height: partition
            anchors {
                //verticalCenter: parent.verticalCenter
                //horizontalCenter: parent.horizontalCenter
                centerIn: parent
            }
        }

        anchors {
            left: parent.left
            right: parent.right
            top: tweet_border.bottom
        }
    }

    Rectangle {
        id: char_counter_border

        width: parent.width
        height: partition * 2

        border.color: "white"
        border.width: 2
        color: "#00000000"

        anchors.top: thobber_border.bottom

        Text {
            id: char_counter
            text: 140 - tweet_area.text.length
            color: "white"

            font.pointSize: 20
            focus: true

            anchors.centerIn: parent
        }

        Button {
            width: 100
            height: partition

            anchors.top: char_counter_border.bottom
            anchors.right: tweet_button.left

            button_text: "cancel"

            onButtonClicked: {
                if (state != "busy")
                    tweet_dialog.state = "hidden"
            }
        }

        Button {
            id: tweet_button

            width: 100
            height: partition

            anchors.top: char_counter_border.bottom
            anchors.right: parent.right

            button_text: "tweet"

            onButtonClicked: {
                sendClicked()
                tweet_dialog.state = "busy"
            }
        }
    }

    states: [
        State {
            name: "hidden"
            PropertyChanges {
                target: tweet_area
                text: ""
            }
            PropertyChanges {
                target: tweet_dialog
                opacity: 0
            }
        },
        State {
            name: "visible"
            PropertyChanges {
                target: tweet_dialog
                opacity: 1
                in_reply: ""
                in_reply_id: ""
                direct_message: false
                direct_message_from: ""
            }
            PropertyChanges {
                target: tweet_area
                text: ""
            }
        },
        State {
            name: "busy"
            PropertyChanges {
                target: thobber_border
                height: partition
            }
            PropertyChanges {
                target: thobber
                playing: true
                visible: true
            }
            PropertyChanges {
                target: tweet_border
                height: partition * 4
            }
            PropertyChanges {
                target: status
                visible: false
            }

        }
    ]

    Behavior on opacity {
        NumberAnimation {
            duration: 250
        }
    }

    Component.onCompleted: {
        tweet_area.focus = true;
    }

    function reset() {
        tweet_area.text = ""
        in_reply = ""
    }
}
