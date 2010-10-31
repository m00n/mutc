import Qt 4.7

Rectangle {
    id: tweet_delegate

    radius: 5
    opacity: 100

    color: "#323436"
    width: 100
    height: 100

    //property string author: "No nick"
    //property string tweet_text: "No text"
    //property date timestamp
    property bool in_reply: false
    property string in_reply_to
    property bool retweet: false
    property string retweeted_by
    property string via: ""


    Row {
        spacing: 5

        Image {
            id: twitter_avatar
            source: author.profile_image_url
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

                Text {
                    id: twitter_time
                    text: Qt.formatDateTime(created_at, "hh:mm:ss")
                    font.pointSize: twitter_name.font.pointSize - 3
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
}
