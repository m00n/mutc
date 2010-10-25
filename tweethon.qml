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

            ListView {
                model: account_model
                orientation: ListView.Horizontal
                height: toolbar_row.height
                width: 200
                delegate: Row {
                    Image {
                        source: avatar
                        height: toolbar_row.height
                        width: toolbar_row.height
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        text: screen_name
                        color: "white"
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
