import Qt 4.7

Rectangle {
    id: tweet_delegate

    radius: 5

    color: "#323436"

    visible: index != ListView.view.model.count - 1 || (index == ListView.view.model.count - 1 && model_busy)
    opacity: visible ? 1.0 : 0.0

    width: 300
    height: index != ListView.view.model.count - 1 ? 120 : 30

    Rectangle {
        id: load_display
        visible: index == ListView.view.model.count - 1

        z: 2

        color: "#323436"
        radius: 5

        anchors.fill: parent

        Item {
            anchors.fill: parent
            visible: model_busy
/*
            Text {
                id: load_text
                text: "Loading tweets"
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    margins: 5
                }
                height: 22
                color: "white"
            }*/

            AnimatedImage {
                id: load_animation
                source: "thobber.gif"
                playing: model_busy

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                    margins: 5
                }
            }
        }
    }

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
        text: author.screen_name
        color: "white"
        font.bold: true

        anchors {
            left: twitter_avatar.right
            top: parent.top
            margins: 5
        }

    }

    URLText {
        id: twitter_text
        text: message
        wrapMode: Text.Wrap
        width: tweet_delegate.width - twitter_avatar.width - 10

        anchors {
            top: twitter_name.bottom
            left: twitter_avatar.right
            margins: 5
        }

        onLinkActivated: {
           app.open_url(link);
        }
    }

    Text {
        id: twitter_time
        text: created_at

        font.pointSize: twitter_name.font.pointSize - 3
        height: 22
        width: parent.width / 4
        color: "white"

        x: 5
        y: parent.height - 18
        /*anchors {
            bottom: parent.bottom
            //left: parent.left
            margins: 2
        }*/
    }

    Text {
        id: rt_by

        y: twitter_time.y
        text: {
            if (is_retweet)
                "\u21BA" + retweet_by.screen_name
            else
                ""
        }
        visible: is_retweet
        color: "white"
        anchors {
            //bottom: parent.bottom
            left: twitter_time.right
            leftMargin: 2
        }
        height: 22
        font.pointSize: twitter_time.font.pointSize
    }

    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }
}
