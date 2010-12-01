import Qt 4.7

Rectangle {
    id: tweet_delegate

    radius: 5

    color: "#323436"

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
            //console.log(ListView.view.model.type)
            if (ListView.view.model.type == "direct messages") {
                //("<b>" + author.screen_name + "</b> to <b>" + in_reply.screen_name + "</b>").replace(, "you")
                if (author.screen_name == you)
                    "to <b>" + in_reply.screen_name
                else
                    "from <b>" + author.screen_name
            } else {
                "<b>" + author.screen_name + "</b>"
            }
        }
        color: "white"
        //font.bold: true

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
        width: tweet_delegate.width - twitter_avatar.width - 15
        z: 10

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
        color: "white"

        x: 5
        y: parent.height - 18
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
        color: "white"
        anchors {
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
