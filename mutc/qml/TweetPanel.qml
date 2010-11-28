import Qt 4.7

Rectangle {
    id: tweet_panel
    width: 320
    height: 480

    property alias model: tweet_view.model
    property bool model_busy
    property bool overlay
    property bool locked
    property Item tweetView: tweet_view

    signal needTweets
    signal reply
    signal retweet(bool comment)
    signal removeTweet
    signal panelsLocked

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
        highlightFollowsCurrentItem: false

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
                    if (!locked) {
                        var coords = ListView.view.mapFromItem(parent, mouseX, mouseY + tweetView.contentY);
                        var idx = ListView.view.indexAt(coords.x, coords.y);

                        if (idx == ListView.view.currentIndex && overlay) {
                            overlay = false
                        } else if (idx != ListView.view.currentIndex && overlay) {
                            overlay = false
                        } else {
                            overlay = true;
                            ListView.view.currentIndex = idx;
                        }
                    }
                }
            }
        }

        footer: Item {
            width: parent.width
            height: 30

            Rectangle {
                id: load_display
                visible: model.busy

                z: 2
                color: "#323436"
                radius: 5

                anchors {
                    topMargin: 2
                    bottomMargin: 2
                    fill: parent
                }

                AnimatedImage {
                    id: load_animation
                    source: "thobber.gif"
                    playing: model.busy

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.verticalCenter
                        margins: 5
                    }
                }
            }
        }

        highlight: Rectangle {
            id: overlay_item
            color: "#00000000"
            opacity: overlay ? 1 : 0
            state: "default"
            z: 5
            y: tweet_view.currentItem.y
            width: tweet_view.width
            height: tweet_view.currentItem.height

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

                AnimatedImage {
                    id: thobber
                    source: "thobber.gif"
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.verticalCenter
                    }
                    opacity: 0
                }

                Item {
                    id: action_panel

                    visible: true

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

                        onButtonClicked: overlay_item.state = "retweet"
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

                        onButtonClicked: {
                            overlay = false
                            tweet_panel.reply()
                        }
                    }

                    Button {
                        id: delete_menu_button
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

                        onButtonClicked: {
                            overlay_item.state = "delete"
                        }

                    }
                }
                Item {
                    id: rt_panel

                    visible: false
                    opacity: visible ? 1 : 0

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 300

                    z: 7
                    Button {
                        id: rt_comment_button
                        button_text: "with comment"
                        default_color: "#000000"
                        width: 120
                        height: parent.height - 10
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.horizontalCenter
                            margins: 15
                        }
                        z: 7

                        onButtonClicked: {
                            overlay = false
                            tweet_panel.retweet(true)
                        }
                    }
                    Button {
                        id: rt_default_button
                        button_text: "normal"
                        default_color: "#000000"
                        width: 120
                        height: parent.height - 10
                        anchors {
                            verticalCenter: parent.verticalCenter
                            right: parent.horizontalCenter
                            margins: 15
                        }
                        z: 7

                        onButtonClicked: {
                            //overlay = false
                            overlay_item.state = "busy"
                            //tweet_panel.panelsLocked()
                            tweet_panel.retweet(false)
                        }
                    }
                }

                Item {
                    id: delete_panel

                    visible: false
                    opacity: visible ? 1 : 0

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 300

                    z: 7
                    Button {
                        id: cancel_delete_button
                        button_text: "cancel"
                        default_color: "#000000"
                        width: 120
                        height: parent.height - 10
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.horizontalCenter
                            margins: 15
                        }
                        z: 7

                        onButtonClicked: {
                            overlay = false
                        }
                    }
                    Button {
                        id: delete_button
                        button_text: "delete"
                        default_color: "#000000"
                        width: 120
                        height: parent.height - 10
                        anchors {
                            verticalCenter: parent.verticalCenter
                            right: parent.horizontalCenter
                            margins: 15
                        }
                        z: 7

                        onButtonClicked: {
                            overlay_item.state = "busy"
                            tweet_panel.removeTweet()
                        }
                    }
                }
            }

            states: [
                State {
                    name: "default"
                    when: overlay
                    PropertyChanges {
                        target: rt_panel
                        visible: false
                    }
                    PropertyChanges {
                        target: action_panel
                        visible: true
                    }
                    PropertyChanges {
                        target: delete_panel
                        visible: false
                    }

                },
                State {
                    name: "busy"
                    PropertyChanges {
                        target: thobber
                        opacity: 1
                        playing: true
                    }
                    PropertyChanges {
                        target: rt_panel
                        opacity: 0
                    }
                    PropertyChanges {
                        target: delete_panel
                        opacity: 0
                    }
                    PropertyChanges {
                        target: action_panel
                        opacity: 0
                    }
                    PropertyChanges {
                        target: tweet_panel
                        locked: true
                    }
                    StateChangeScript {
                        script: tweet_panel.panelsLocked()
                    }
                },
                State {
                    name: "retweet"
                    PropertyChanges {
                        target: rt_panel
                        visible: true
                    }
                    PropertyChanges {
                        target: action_panel
                        visible: false
                    }

                },
                State {
                    name: "delete"
                    PropertyChanges {
                        target: delete_panel
                        visible: true
                    }
                    PropertyChanges {
                        target: action_panel
                        visible: false
                    }

                }
            ]


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
