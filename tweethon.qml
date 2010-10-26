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
        anchors.bottom: tweethon.bottom
        anchors.left: tweethon.left

        SystemPalette { id: activePalette }

        Button {
            id: tweet_dialog_button
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
            anchors {
                left: parent.left
                //right: account_view.left
            }
        }

        ListView {
            id: account_view

            model: account_model
            orientation: ListView.Horizontal
            height: toolbar_row.height
            //width: 200
            //focus: true
            //currentIndex: 1
            anchors.left: tweet_dialog_button.right
            anchors.leftMargin: 30 /* XXX */
            anchors.right: parent.right
            spacing: 5
            interactive: false

            delegate: account_delegate
        }

        Component {
            id: account_delegate

            Rectangle {
                height: 22
                width: (screen_name_text.paintedWidth) + 23

                color: "#00000000"

                Rectangle {
                    opacity: active ? 1.0 : 0.0
                    x: 0
                    y: 1
                    width: screen_name_text.width + 1
                    height: 22 - 2
                    color: "steelblue"
                    z: -1

                    Behavior on opacity {
                        NumberAnimation { duration: 250 }
                    }
                }
                Rectangle {
                    opacity: active ? 1.0 : 0.0
                    x: avatar_image.x
                    y: avatar_image.y + 1
                    width: avatar_image.width
                    height: avatar_image.height - 2
                    color: "steelblue"
                    z: -1

                    Behavior on opacity {
                        NumberAnimation { duration: 250 }
                    }

                }

                Image {
                    id: avatar_image
                    source: avatar
                    height: 22
                    width: 22
                    fillMode: Image.PreserveAspectFit
                    smooth: true

                    anchors {
                        top: parent.top

                        right: screen_name_text.left
                        leftMargin: 5
                    }
                }

                Text {
                    id: screen_name_text
                    text: screen_name
                    color: "white"

                    anchors {
                        left: avatar.right
                        leftMargin: 5
                        verticalCenter: parent.verticalCenter
                    }

                    MouseArea {
                        height: 22
                        width: screen_name_text.width

                        z: 100
                        onClicked: {
                            var coords = account_view.mapFromItem(screen_name_text, mouseX, mouseY);
                            var idx = account_view.indexAt(coords.x, coords.y);
                            var data = account_model.get(idx);
                            data.active = !data.active;
                            account_model.set(idx, data);

                        }
                    }
                }
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
            active: false
        }
    }

    TweetDialog {
        id: twitter_dialog
        opacity: 0
        anchors.bottom: toolbar_row.top
        anchors.left: parent.left
    }

    Component.onCompleted: {
       console.log(account_view.x)
    }
}
