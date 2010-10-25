import Qt 4.7

Rectangle {
    id: tweethon

    width: 320
    height: 480

    signal newPanel /* { type: x, args: [] } */
    signal needTweets /* { type: x, account: y, since: z } */

    signal addAccount  /* */
    signal delAccount  /* */

    signal sendTweet /* { accounts: [], text: "", } */
    signal sendReTweet /* { accounts: [], id: int } */

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
        z: 2
        anchors.bottom: tweethon.bottom

        SystemPalette { id: activePalette }

        Row {
            spacing: 20

            Button {
                button_text: "t"
                width: 25
                height: toolbar_row.height
                onButtonClicked: {
                    console.log(twitter_dialog.opacity)
                    if (twitter_dialog.opacity == 1)
                        twitter_dialog.opacity = 0;
                    else
                        twitter_dialog.opacity = 1;
                }
            }

            Component {
                id: account_delegate
                Row {
                    id: account_delegate_row
                    Image {
                        source: avatar
                        height: toolbar_row.height
                        width: toolbar_row.height
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        id: screen_name_text
                        text: screen_name
                        color: "white"
                        font.underline: active
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    /*
                    MouseArea {
                        width: tweethon.width
                        height: 22
                        width: screen_name_text.width

                        onClicked: {
                            console.log("clicked");
                            var idx = account_view.indexAt(mouseX, mouseY);
                            var data = account_model.get(idx);
                            data.active = !data.active;
                        }
                    }*/
                }
            }

            ListView {
                id: account_view
                z: 0
                model: account_model
                orientation: ListView.Horizontal
                height: toolbar_row.height
                width: 200
                /*highlight: Rectangle {
                    color: Qt.lighter(toolbar_row.color, 1.7)
                    z: 0
                }*/
                focus: true
                currentIndex: 1
                interactive: false

                delegate: account_delegate
                /*
                MouseArea {
                    anchors.fill: parent.fill
                    onClicked: {
                        console.log("clicked");
                        var idx = account_view.indexAt(mouseX, mouseY);
                        var data = account_model.get(idx);
                        data.active = !data.active;
                    }
                }*/
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
            oauth: "abcde"
            screen_name: "boringplanet"
            avatar: "m00n_s.png"
            active: false
        }

        ListElement {
            oauth: "abcde"
            screen_name: "tweethon_test"
            avatar: "m00n_s.png"
            active: true
        }
    }

    TweetDialog {
        id: twitter_dialog
        opacity: 0
        anchors.bottom: toolbar_row.top
        anchors.left: parent.left
    }

    Component.onCompleted: {

    }
}
