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
            if (ListView.view.model.type == "direct messages") {
                if (author.screen_name == you)
                    "to <b>" + in_reply.screen_name
                else
                    "from <b>" + author.screen_name
            } else {
                "<b>" + author.screen_name + "</b>"
            }
        }
        color: "white"

        anchors {
            left: twitter_avatar.right
            top: parent.top
            margins: 5
        }

    }

    Flow {
        id: text_flow

        property string text: message
        property color color: "white"

        z: 10

        width: tweet_delegate.width - twitter_avatar.width - 15
        height: 100

        anchors {
            top: twitter_name.bottom
            left: twitter_avatar.right
            margins: 5
        }

        spacing: 3

        Repeater {
            id: repeater

            model: ListModel {
            }

            Text {
                property string decoration: "none"

                color: text_flow.color
                font.underline: islink && part_mousearea.containsMouse
                text: part

                MouseArea {
                    id: part_mousearea
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }

        Component.onCompleted: {
            var splitted = text.split(" ")
            for (var i = 0; i < splitted.length; i++) {
                var part = splitted[i]
                var url = null
                var islink = false

                if (part.substr(0, 1) == "@") {
                    url = "http://twitter.com/" + part.substr(1)
                    islink = true
                } else if (part.substr(0, 1) == "#") {
                    url = "search://" + part.substr(1)
                    islink = true
                } else if (part.match(/(http:\/\/\S*)/g)) {
                    url = part
                    islink = true
                }

                repeater.model.append({"part": part, "islink": islink, "url": url})
            }
        }
    }

    Text {
        id: twitter_time
        text: created_at

        font.pointSize: twitter_name.font.pointSize - 3
        font.underline: twitter_time_mouse_area.containsMouse
        height: 22
        color: "white"

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
        color: "white"
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

        visible: in_reply ? true : false

        text: "In reply to " + in_reply
        color: "white"

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

    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }
}
