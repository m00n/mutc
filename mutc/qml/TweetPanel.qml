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
    signal undoRetweet
    signal favorite
    signal undoFavorite
    signal removeTweet
    signal panelsLocked

    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: style.gradientStart

        }
        GradientStop {
            position: 1.0
            color: style.gradientStop
        }

    }

    Style { id: style }

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
            color: style.textColor
            font.underline: index == tweet_panel.ListView.view.currentIndex

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
                tweet_panel.ListView.view.model.move(index, index - 1);
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
                tweet_panel.ListView.view.model.move(index, index + 1);
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
                tweet_panel.ListView.view.model.remove(index)
            }
        }

        z: 1
    }

    ListView {
        id: tweet_view
        model: tweet_model
        spacing: 2
        highlightFollowsCurrentItem: false

        signal emulateClick

        property string panel_screen_name: screen_name
        property int currentOverlayIndex: 0
        property int overlayItemCount: 0

        anchors {
            top: title_rect.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        delegate: TweetDelegate {
            width: parent ? parent.width : 300
            height: type == "wall" ? 72 : 120

            MouseArea {
                anchors.fill: parent
                onDoubleClicked: {
                    if (!locked) {
                        var coords = tweet_view.mapFromItem(parent, mouseX, mouseY + tweetView.contentY);
                        var idx = tweet_view.indexAt(coords.x, coords.y);

                        if (idx == tweet_view.currentIndex && overlay) {
                            overlay = false
                        } else if (idx != tweet_view.currentIndex && overlay) {
                            overlay = false
                        } else {
                            overlay = true;
                            tweet_view.currentIndex = idx;
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
                color: style.backgroundColor
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

        highlight: TweetOverlay {
            id: tweet_overlay

            onRetweet: tweet_panel.retweet(comment)
            onReply: tweet_panel.reply()
            onRemoveTweet: tweet_panel.removeTweet()
            onUndoRetweet: tweet_panel.undoRetweet()
            onFavorite: tweet_panel.favorite()
            onUndoFavorite: tweet_panel.undoFavorite()
            onLock: tweet_panel.panelsLocked()

            function set_index_in_view () {
                tweet_view.currentOverlayIndex = tweet_overlay.view.currentIndex
            }
            function set_index_in_overlay () {
                tweet_overlay.view.currentIndex = tweet_view.currentOverlayIndex
            }
            function on_view_model_changed () {
                tweet_view.overlayItemCount = view.model.count
            }
            function f () {
                tweet_overlay.view.currentItem.buttonClicked()
            }

            Component.onCompleted: {
                tweet_overlay.view.currentIndexChanged.connect(set_index_in_view)
                tweet_overlay.view.modelChanged.connect(on_view_model_changed)
                tweet_view.currentOverlayIndexChanged.connect(set_index_in_overlay)
                tweet_view.emulateClick.connect(f)

                tweet_view.overlayItemCount = view.model.count

            }
            Component.onDestruction: {
                tweet_overlay.view.currentIndexChanged.disconnect(set_index_in_view)
                tweet_overlay.view.modelChanged.disconnect(on_view_model_changed)
                tweet_view.currentOverlayIndexChanged.disconnect(set_index_in_overlay)
            }
        }

        onMovementEnded: {
            if (tweet_view.atYEnd) {
                if (!model.busy && model.count > 0)
                {
                    needTweets()
                }

            }
        }
    }
}
