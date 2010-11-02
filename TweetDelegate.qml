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
    }

    Text {
        id: twitter_time
        text: created_at

        font.pointSize: twitter_name.font.pointSize - 3
        height: 22
        color: "white"

        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: 0
        }
    }

    /*
    Row {
        spacing: 5

        Image {
            id: twitter_avatar
            source: author.profile_image_url
            x: 5
            y: tweet_delegate.height / 2 - (height / 2)
        }

        Column {
            id: inner_tweet
            spacing: 1

            Text {
                id: twitter_name
                text: author.screen_name
                color: "white"
                font.bold: true
            }
            URLText {
                id: twitter_text
                text: message
                wrapMode: Text.Wrap
                width: tweet_delegate.width - 60
            }

            Row {
                spacing: 10
                width: tweet_delegate.width - 5
                Text {
                    id: twitter_time
                    text: created_at

                    font.pointSize: twitter_name.font.pointSize - 3
                    height: 22
                    color: "white"
                }
                Text {
                    id: twitter_inreply
                    text: in_reply_to
                    font.pointSize: twitter_time.font.pointSize
                    color: "white"
                    visible: in_reply
                }
                Text {
                    id: twitter_rt
                    text: "Retweeted by"
                    font.pointSize: twitter_time.font.pointSize
                    color: "white"
                    visible: retweet
                }
                Text {
                    id: twitter_via
                    text: via
                    font.pointSize: twitter_time.font.pointSize
                    color: "white"
                    visible: via.length > 0
                }
            }
        }
    }
    */
}
