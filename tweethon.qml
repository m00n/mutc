import Qt 4.7

Rectangle {
    id: tweethon

    width: 320
    height: 480

    signal subscribe /* emitted when a new panel is created { account: id, type: panel_type, args: [] } */
    signal needTweets /* { type: x, account: y, since: z } */

    signal addAccount  /* */
    signal delAccount  /* */

    signal sendTweet /* { accounts: [], text: "", } */
    signal sendReTweet /* { accounts: [], id: int } */

    signal needAuthURL /* {  } */
    signal guiReady

    //property accounts list

    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: "#4d5053"

        }
        GradientStop {
            position: 1.0
            color: "#6d7176"
        }

    }

    ListView {
        id: tweet_panels
        model: tweet_panel_model
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        delegate: TweetPanel {
            anchors.top: { if (parent) parent.top }
            anchors.bottom: { if (parent) parent.bottom }
        }
        width: parent.width

        anchors.top: tweethon.top
        anchors.bottom: toolbar_row.top

        spacing: 10
    }

    Toolbar {
        id: toolbar_row
        height: 22
        anchors.bottom: tweethon.bottom
        anchors.left: tweethon.left

        SystemPalette { id: activePalette }

        Button {
            id: tweet_dialog_button
            button_text: "t"
            width: 25
            height: toolbar_row.height
            onButtonClicked: {
                if (twitter_dialog.opacity == 1)
                    twitter_dialog.opacity = 0;
                else
                    twitter_dialog.opacity = 1;
            }
            anchors {
                left: parent.left
            }

            border {
                width: toolbar_row.border.width
                color: toolbar_row.border.color
            }
        }

        ListView {
            id: account_view

            model: account_model
            orientation: ListView.Horizontal
            height: toolbar_row.height

            anchors {
                left: tweet_dialog_button.right
                leftMargin: 30 /* XXX */
                right: menu_button.left
            }

            spacing: 0
            interactive: false

            delegate: AccountDelegate {}
        }
        Button {
            id: menu_button
            button_text: "+"
            width: 25
            height: toolbar_row.height
            //anchors.left: account_view.right
            anchors.right: parent.right
            anchors.top: toolbar_row.top

            border {
                width: toolbar_row.border.width
                color: toolbar_row.border.color
            }
            onButtonClicked: {
                if (tweethon_menu.state == "hidden")
                    tweethon_menu.state = "main_menu"
                else
                    tweethon_menu.state = "hidden"
            }
        }
    }




    ListModel {
        id: tweet_panel_model

        ListElement {
            panel_type: "friends"
            account: "boringplanet"
        }
        ListElement {
            panel_type: "friends"
            account: "boringplanet"
        }
        ListElement {
            panel_type: "friends"
            account: "boringplanet"
        }

    }

    ListModel {
        id: account_model

        ListElement {
            uuid: ""
            oauth: "abcde"
            screen_name: "boringplanet"
            avatar: "m00n_s.png"
            active: false
        }

        ListElement {
            uuid: ""
            oauth: "abcde"
            screen_name: "tweethon_test"
            avatar: "m00n_s.png"
            active: false
        }
    }

    ListModel {
        id: panel_model

        ListElement {
            type: 'timeline'
        }
        ListElement {
            type: 'mentions'
        }
    }

    TweetDialog {
        id: twitter_dialog
        opacity: 0
        anchors.bottom: toolbar_row.top
        anchors.left: parent.left
        anchors.margins: 1
    }

    Rectangle {
        id: tweethon_menu
        opacity: 0

        width: 320
        height: 240

        color: "#323436"

        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }

        TitleBar {
            id: title
            text: "Tweethon menu"
            color: border.color
        }
        Button {
            id: add_account_button
            button_text: "Add account"
            height: 22
            width: parent.width
            border {
                width: title.border.width
                color: title.border.color
            }
            anchors {
                top: title.bottom
                left: parent.left
                right: parent.right
                topMargin: 5
            }
            onButtonClicked: {
                new_account_dialog.state = 'open'
            }
        }

        ListView {
            id: account_menu_view

            model: account_model


            delegate: Button {
                button_text: "Create panel for `" + screen_name + "` >"
                height: 22
                width: 320
                border {
                    width: title.border.width
                    color: title.border.color
                }
                onButtonClicked: {
                    panel_view.for_account = uuid
                    tweethon_menu.state = "panel_menu"
                }
            }

            anchors {
                top: add_account_button.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: 5
            }
        }

        ListView {
            id: panel_view
            model: panel_model

            property string for_account

            delegate: Button {
                button_text: type
                height: 22
                width: 320

                border {
                    width: title.border.width
                    color: title.border.color
                }

                onButtonClicked: {
                    tweethon_menu.state = "hidden";
                    twitter.subscribe({
                        'account': panel_view.for_account,
                        'type': type
                    });
                }
            }
            anchors {
                top: add_account_button.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: 5
            }
        }

        anchors {
            bottom: toolbar_row.top
            right: parent.right
        }

        state: "hidden"

        states: [
            State {
                name: "main_menu"
                PropertyChanges {
                    target: account_menu_view
                    opacity: 1
                }
                PropertyChanges {
                    target: panel_view
                    opacity: 0
                }
                PropertyChanges {
                    target: tweethon_menu
                    opacity: 1
                }
            },
            State {
                name: "panel_menu"
                PropertyChanges {
                    target: account_menu_view
                    opacity: 0
                }
                PropertyChanges {
                    target: panel_view
                    opacity: 1
                }
                PropertyChanges {
                    target: tweethon_menu
                    opacity: 1
                }
            },
            State {
                name: "hidden"
                PropertyChanges {
                    target: tweethon_menu
                    opacity: 0
                }
            }

        ]
        transitions: [
            Transition {
                NumberAnimation { property: "opacity"; duration: 250 }
            }
        ]


    }

    NewAccoutDialog {
        id: new_account_dialog
        anchors.centerIn: parent
    }

    Component.onCompleted: {
        if (app) {
            app.backendReady.connect(function () {
                console.log("Backend ready");
                guiReady();
            })
            app.announceAccount.connect(function (data) {
                account_model.append(data)
                console.log(data)
            })
        }
    }
}
