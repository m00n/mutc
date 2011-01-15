import Qt 4.7

Rectangle {
    id: overlay_item
    color: "#00000000"
    opacity: overlay ? 1 : 0
    state: "default"
    z: 5
    y: ListView.view ? ListView.view.currentItem.y : 0
    width: ListView.view ? ListView.view.width : 0
    height: ListView.view ? ListView.view.currentItem.height : 0

    property alias view: action_view

    signal reply
    signal retweet(bool comment)
    signal undoRetweet
    signal removeTweet
    signal lock


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

        VisualItemModel {
            id: action_model

            property int buttonWidth: 30
            property int neededWidth: (buttonWidth * 3) + 20

            TweetOverlayButton {
                id: rt_button
                button_text: "\u21BA"

                onButtonClicked: {
                    if (ListView.view.currentItem.dataMyRetweet)
                        overlay_item.state = "undo-retweet"
                    else
                        overlay_item.state = "retweet"
                }
            }

            TweetOverlayButton {
                id: reply_button
                button_text: "\u21B7"

                onButtonClicked: {
                    overlay = false
                    overlay_item.reply()
                }
            }

            TweetOverlayButton {
                id: delete_menu_button
                button_text: "x"

                onButtonClicked: {
                    overlay_item.state = "delete"
                }
            }
        }

        VisualItemModel {
            id: rt_model

            property int buttonWidth: 120
            property int neededWidth: (buttonWidth * 2) + 10


            TweetOverlayButton {
                id: rt_default_button
                button_text: "normal"

                onButtonClicked: {
                    overlay_item.state = "busy"
                    overlay_item.retweet(false)
                }
            }

            TweetOverlayButton {
                id: rt_comment_button
                button_text: "with comment"

                onButtonClicked: {
                    overlay = false
                    overlay_item.retweet(true)
                }
            }
        }

        VisualItemModel {
            id: rt_undo_model

            property int buttonWidth: 120
            property int neededWidth: (buttonWidth * 2) + 10

            TweetOverlayButton {
                id: rt_undo_button
                button_text: "undo rt"

                onButtonClicked: {
                    overlay_item.state = "busy"
                    overlay_item.undoRetweet()
                }
            }
            TweetOverlayButton {
                id: rt_cancel_undo_button
                button_text: "cancel"

                onButtonClicked: {
                    overlay = false
                }
            }
        }

        VisualItemModel {
            id: delete_model

            property int buttonWidth: 120
            property int neededWidth: (buttonWidth * 2) + 10

            TweetOverlayButton {
                id: cancel_delete_button
                button_text: "cancel"

                onButtonClicked: {
                    overlay = false
                }
            }
            TweetOverlayButton {
                id: delete_button
                button_text: "delete"

                onButtonClicked: {
                    overlay_item.state = "busy"
                    overlay_item.removeTweet()
                }
            }
        }

        ListView {
            id: action_view

            visible: true
            interactive: false

            anchors.centerIn: parent

            width: model.neededWidth
            height: 30

            z: 7

            model: action_model
            orientation: ListView.Horizontal

            spacing: 10

            highlightFollowsCurrentItem: false
            highlight: Rectangle {
                color: "#00000000"

                x: safe_get("x", -2)
                y: safe_get("y", -2)
                height: safe_get("height", 4)
                width: safe_get("width", 4)
                z: 10


                border {
                    width: 2
                    color: "black"
                }

                function safe_get(prop, offset) {
                    if (ListView.view) {
                        return ListView.view.currentItem[prop] + offset
                    }
                    else {
                        return 0
                    }
                }
            }

            onModelChanged: {
                currentIndex = 1
                currentIndex = 0
            }

            Component.onCompleted: {
                /* XXX this enforces redrawing the highlight which doesn't get displayed
                   correctly otherweise
                */
                currentIndex = 0
                currentIndex = 1
                currentIndex = 0
            }
        }
    }

    states: [
        State {
            name: "default"
            when: overlay

            PropertyChanges {
                target: action_view
                model: action_model
                currentIndex: 0
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
                target: action_view
                opacity: 0
            }
            PropertyChanges {
                target: tweet_panel
                locked: true
            }
            StateChangeScript {
                script: overlay_item.lock()
            }
        },
        State {
            name: "retweet"

            PropertyChanges {
                target: action_view
                model: rt_model
                currentIndex: 0
            }

        },
        State {
            name: "undo-retweet"
            PropertyChanges {
                target: action_view
                model: rt_undo_model
                currentIndex: 0
            }
        },
        State {
            name: "delete"
            PropertyChanges {
                target: action_view
                model: delete_model
                currentIndex: 0
            }
        }
    ]

    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }
}
