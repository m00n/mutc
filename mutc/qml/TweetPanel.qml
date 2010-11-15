import Qt 4.7

Rectangle {
    id: tweet_panel
    width: 320
    height: 480
    //color: "red"

    property int max_tweets: 30
    property alias model: tweet_view.model
    /*property string account: "no account"
    property string account_oid: "no oid"
    property string panel_type: "timeline"*/

    /*
        "friends"
        "mentions"
        "search"
    */

    signal needTweets

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

    Toolbar {
        id: title_rect
        anchors.top: parent.top
        height: 22

        Text {
            x: 5
            text: {
                if (args)
                    "@" + screen_name + "/" + type + "(" + args + ")"
                else
                    "@" + screen_name + "/" + type
            }
            color: "white"

            anchors.verticalCenter: parent.verticalCenter
        }

        Button {
            id: move_left_button
            button_text: "<"
            height: 15
            width: 15

            anchors.right: move_right_button.left
            anchors.verticalCenter: parent.verticalCenter

            border {
                width: 1
                color: title_rect.border.color
            }
            onButtonClicked: {
                ListView.view.model.move(index, index - 1);
            }
        }
        Button {
            id: move_right_button
            button_text: ">"
            height: 15
            width: 15

            anchors.right: close_button.left
            anchors.verticalCenter: parent.verticalCenter

            border {
                width: 1
                color: title_rect.border.color
            }

            onButtonClicked: {
                ListView.view.model.move(index, index + 1);
            }
        }
        Button {
            id: close_button
            button_text: "x"
            height: 15
            width: 15

            anchors.right: parent.right
            anchors.rightMargin: 3
            anchors.verticalCenter: parent.verticalCenter

            border {
                width: 1
                color: title_rect.border.color
            }


            onButtonClicked: {
                ListView.view.model.remove(index);
            }
        }

        z: 1
    }

    ListView {
        id: tweet_view
        model: tweet_model
        spacing: 2

        anchors {
            top: title_rect.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        delegate: TweetDelegate {
            width: {
                if (parent)
                    parent.width
                else
                    300
            }
        }
        onMovementEnded: {
            //console.log(tweet_view.contentHeight + " " + tweet_view.contentY)
            if (tweet_view.atYEnd) {
                //console.log("atyend");
                if (!new_tweet_timeout.running)
                {
                    needTweets()
                    new_tweet_timeout.start()
                }

            }
        }
    }

    Timer {
        id: new_tweet_timeout
        interval: 3000
        repeat: false
        running: false
    }

    ListModel {
        id: tweet_model
        /*
        ListElement {
            author: "boringplanet"
            tweet_text: "Faketweet test das ist ein test blablubb foo bar baz bazinga zort hoot hoot hoot"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "gdfg gfdgf http://foo.bar.baz/zort"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }*/
    }

    Component.onCompleted: {
        console.log("Panel");
        //console.log("> " + pyobj.get_foo() + "<");
        //console.log("> " + zort() + "<");
    }
}
