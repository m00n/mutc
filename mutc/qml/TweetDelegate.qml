import Qt 4.7

Rectangle {
    id: tweet_delegate

    radius: 5
    opacity: 100

    color: "#323436"
    width: 300
    height: 120

    //property string author: "No nick"
    //property string tweet_text: "No text"
    //property date timestamp
    property bool in_reply: false
    property string in_reply_to
    property bool retweet: false
    property string retweeted_by
    property string via: ""

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
}
