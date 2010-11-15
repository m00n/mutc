import Qt 4.7


Rectangle {
    id: tweet_dialog

    width: 320
    height: 240

    SystemPalette { id: activePalette }

    color: "#323436"

    property int partition: height / 8

    Rectangle {
        id: tweet_border

        width: parent.width
        height: partition * 5

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
        }

        anchors.top: parent.top
    }

    Rectangle {
        id: char_counter_border

        width: parent.width
        height: partition * 2

        border.color: "white"
        border.width: 2
        color: "#00000000"

        anchors.top: tweet_border.bottom

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
                tweet_area.text = ""
                tweet_dialog.opacity = 0;
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
                tweet_dialog.opacity = 0;
            }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 250
        }
    }

    Component.onCompleted: {
        tweet_area.focus = true;
    }
}