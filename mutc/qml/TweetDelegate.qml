import Qt 4.7

Rectangle {
    id: tweet_delegate

    radius: 5

    Style { id: style }

    color: style.backgroundColor

    width: 300
    height: 120

    property bool dataMyRetweet: my_retweet

    Image {
        id: twitter_avatar
        source: author.profile_image_url

        width: 48
        height: 48

        fillMode: Image.PreserveAspectFit

        anchors {
            left: parent.left
            top: parent.top
            verticalCenter: parent.verticalCenter

            margins: 5
        }
    }

    Text {
        id: twitter_name
        text: {
            var you = ListView.view.panel_screen_name
            if (ListView.view.model.type == "direct messages") {
                if (author.screen_name == you)
                    "to <b>" + in_reply.screen_name
                else
                    "from <b>" + author.screen_name
            } else {
                "<b>" + author.screen_name + "</b>"
            }
        }
        color: style.textColor

        anchors {
            left: twitter_avatar.right
            top: parent.top
            margins: 5
        }

    }

    TweetText {
        id: tweet_text
        text: message

        z: 10

        width: tweet_delegate.width - twitter_avatar.width - 15
        height: 100

        anchors {
            top: twitter_name.bottom
            left: twitter_avatar.right
            margins: 5
        }
    }

    Text {
        id: twitter_time
        text: created_at

        font.pointSize: twitter_name.font.pointSize - 3
        font.underline: twitter_time_mouse_area.containsMouse
        height: 22
        color: style.textColor

        x: 5
        y: parent.height - 18
        z: 10

        MouseArea {
            id: twitter_time_mouse_area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                app.open_url("http://twitter.com/#!/" + author.screen_name + "/status/" + tweet_id)
            }
        }
    }

    Text {
        id: rt_by

        y: twitter_time.y
        text: {
            if (is_retweet)
                "\u21BA" + (my_retweet ? " you" : retweet_by.screen_name)
            else
                ""
        }
        visible: is_retweet
        color: style.textColor
        anchors {
            left: twitter_time.right
            leftMargin: 2
        }
        height: 22
        font.pointSize: twitter_time.font.pointSize
    }

    Text {
        y: parent.height - 18
        z: 10

        visible: in_reply && ListView.view.model.type != "direct messages" ? true : false

        text: "In reply to " + in_reply
        color: style.textColor

        anchors {
            right: parent.right
            rightMargin: 5
        }
        font.pointSize: twitter_time.font.pointSize
        font.underline: (in_reply_id && mouse_area.containsMouse) ? true : false

        MouseArea {
            id: mouse_area
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                if (in_reply_id)
                    app.open_url("http://twitter.com/#!/" + in_reply + "/status/" + in_reply_id)
            }
        }
    }

    Rectangle {
        radius: 10
        height: 11
        width: 11
        color: style.indexPointColor

        anchors {
            top: parent.top
            right: parent.right
            margins: 5
        }

        visible: index == ListView.view.currentIndex
    }

    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }
}
