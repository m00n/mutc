import Qt 4.7

Rectangle {
    width: 640
    height: 320

    id: new_account_dialog

    color: "#323436"

    property string account /* uuid */
    property string auth_url: ""
    property string waiting_str: "Waiting for authentication url"


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
    /*URLText {
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
    }*/

    Rectangle {
        id: auth_url_border

        height: 44
        color: "#00000000"

        anchors {
            top: auth_text.bottom
            left: parent.left
            right: parent.right
            margins: 3

        }

        border {
            width: 1
            color: "white"
        }

        TextEdit {
            id: auth_url_text
            color: "white"

            anchors {
                fill: parent
                margins: 4
            }

            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap

            selectByMouse: true

            text: {
                if (auth_url)
                    auth_url
                else
                    waiting_str
            }
        }
    }

    Rectangle {
        height: 44
        color: "#00000000"
        anchors {
            top: auth_url_border.bottom
            left: parent.left
            right: parent.right
            margins: 4

        }
        border {
            width: 1
            color: "white"
        }

        TextInput {
            id: verifier_input

            text: "enter verifier code"
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            anchors {
                fill: parent
                margins: 4
            }

            selectByMouse: true
            Component.onCompleted: {
                //verfier_input.selectAll()
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

        onButtonClicked: {
            twitter.account(account).set_verifier(verifier_input.text);
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

        onButtonClicked: {
            new_account_dialog.state = ""
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

    function init () {
        var account_obj = twitter.new_account();
        new_account_dialog.account = account_obj.get_uuid();
        account_obj.authURLReady.connect(function (url) {
            new_account_dialog.auth_url = url;
        });
        account_obj.request_auth();
        console.log(account_obj)
    }

    onStateChanged: {
        if (new_account_dialog.state == "") {
            console.log("hiding")
            new_account_dialog.auth_url = "";
            twitter.dismiss_account(new_account_dialog.account);
        }
    }
}
