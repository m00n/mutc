import Qt 4.7

Rectangle {
    id: tweet_panel
    width: 320
    height: 480

    property alias model: tweet_view.model
    property bool overlay: true
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

    MouseArea {
        anchors.fill: parent

        onClicked: {
            console.log("!")
            overlay = false
        }
        //z: 10
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

            MouseArea {
                anchors.fill: parent
                onDoubleClicked: {
                    var coords = ListView.view.mapFromItem(parent, mouseX, mouseY);
                    var idx = ListView.view.indexAt(coords.x, coords.y);

                    if (idx == ListView.view.currentIndex && overlay) {
                        overlay = false;
                    } else {
                        overlay = true;
                        ListView.view.currentIndex = idx;
                    }
                }
            }
        }

        highlight: Rectangle {
            color: "#00000000"
            opacity: overlay ? 1 : 0
            z: 5

            Rectangle {
                color: "steelblue"
                opacity: 0.9
                anchors.fill: parent
            }

            Item {
                height: parent.height / 3
                z: 7

                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 300

                    z: 7
                    Button {
                        id: rt_button
                        button_text: "\u21BA"
                        default_color: "#000000"
                        width: 30
                        height: parent.height - 10
                        anchors {
                            verticalCenter: parent.verticalCenter
                            right: reply_button.left
                            margins: 15
                        }
                        z: 7
                    }

                    Button {
                        id: reply_button
                        button_text: "\u21B7"
                        default_color: "#000000"
                        width: 30
                        height: parent.height - 10
                        anchors {
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.horizontalCenter
                            //left: rt_button.right
                            //right: delete_button.left
                            margins: 15
                        }
                        z: 7

                    }

                    Button {
                        id: delete_button
                        button_text: "x"
                        default_color: "#000000"
                        width: 30
                        height: parent.height - 10
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: reply_button.right
                            margins: 15
                        }
                        z: 7

                    }
                }

            }

            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }

        Timer {
            id: new_tweet_timeout
            interval: 3000
            repeat: false
            running: false
        }

        onMovementEnded: {
            if (tweet_view.atYEnd) {
                if (!new_tweet_timeout.running && model.count > 0)
                {
                    needTweets()
                    new_tweet_timeout.start()
                }

            }
        }
    }
}
