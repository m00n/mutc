import Qt 4.7

Rectangle {
    width: 320
    height: 240

    id: new_account_dialog

    color: "#323436"


    SystemPalette { id: activePalette }

    border.width: 2
    border.color: activePalette.shadow

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
            text: "Add account to tweethon"
            color: "white"
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
        }
    }

    URLText {
        id: info_text
        anchors {
            top: title_bar.bottom
            left: parent.left
            right: parent.right
            topMargin: 10
            margins: 3
        }

        wrapMode: Text.Wrap
        text: "You must already have a twitter account, if not visit http://twitter.com/signup to set one up"
    }
    URLText {
        id: auth_text
        anchors {
            top: info_text.bottom
            left: parent.left
            right: parent.right
            margins: 3
        }

        wrapMode: Text.Wrap
        text: "If you have a twitter account please visit the url below and paste the verifier code below the url"
    }
    URLText {
        id: auth_url_text

        anchors {
            top: auth_text.bottom
            left: parent.left
            right: parent.right
            margins: 3

        }
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        wrapMode: Text.Wrap
        text: "Waiting for authorization url"
    }

    Rectangle {
        height: 44
        color: "#00000000"
        anchors {
            top: auth_url_text.bottom
            left: parent.left
            right: parent.right
            margins: 4

        }
        border {
            width: 1
            color: "white"
        }

        TextInput {
            id: verfier_input

            text: "enter verifier code"
            color: "white"

            anchors {
                fill: parent
                margins: 4
            }


            Component.onCompleted: {
                verfier_input.selectAll()
            }
        }
    }

    Button {
        id: ok_button
        button_text: "add account"
        width: parent.width / 3
        height: 30

        anchors {
            bottom: parent.bottom
            right: parent.right
            topMargin: 5
            bottomMargin: 1
        }
    }

    Button {
        id: cancel_button
        button_text: "cancel"
        width: parent.width / 3
        height: 30

        anchors {
            bottom: parent.bottom
            right: ok_button.left
            topMargin: 5
            bottomMargin: 1
        }
    }

    opacity: 0
    states: [
        State {
            name: "open"
            PropertyChanges {
                target: new_account_dialog
                opacity: 1
            }
        }
    ]
    transitions: [
        Transition {
            NumberAnimation { property: "opacity"; duration: 250 }
        }
    ]

}
