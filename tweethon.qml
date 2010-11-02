import Qt 4.7

import "tweethon.js" as Tweethon

Rectangle {
    id: tweethon

    width: 320
    height: 480

    signal guiReady

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

    ListView {
        id: tweet_panels
        model: tweet_panel_model
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        delegate: TweetPanel {
            id: tweet_panel
            property bool connected: false
            anchors.top: { if (parent) parent.top }
            anchors.bottom: { if (parent) parent.bottom }

            onNeedTweets: {
                twitter.need_tweets({
                    "uuid": uuid,
                    "type": type,
                    "args": args,
                    "before": tweet_panel.model.get(tweet_panel.model.count - 1).id
                });
            }

            Component.onCompleted: {
                console.log("Delegate completed")
                if (!connected) {
                    console.log("Firstload");
                    connected = true;
                    twitter.newTweets.connect(function (data) {
                        console.log("newTweets");
                        if (data.uuid == uuid && data.type == type && data.args == args) {
                            console.log("mytweets");
                            Tweethon.each(data.tweets, function (index, tweet_data) {
                                if (data.insert == "top") {
                                    tweet_panel.model.insert(index, tweet_data);
                                } else {
                                    tweet_panel.model.append(tweet_data);
                                }
                            });
                        }


                    })
                }
            }
            Component.onDestroyed: {
                console.log("Delegate destroyed");

            }

        }
        width: parent.width

        anchors.top: tweethon.top
        anchors.bottom: toolbar_row.top

        spacing: 10
    }

    Toolbar {
        id: toolbar_row
        height: 22
        anchors.bottom: tweethon.bottom
        anchors.left: tweethon.left

        SystemPalette { id: activePalette }

        Button {
            id: tweet_dialog_button
            button_text: "t"
            width: 25
            height: toolbar_row.height
            onButtonClicked: {
                if (twitter_dialog.opacity == 1)
                    twitter_dialog.opacity = 0;
                else
                    twitter_dialog.opacity = 1;
            }
            anchors {
                left: parent.left
            }

            border {
                width: toolbar_row.border.width
                color: toolbar_row.border.color
            }
        }

        ListView {
            id: account_view

            model: account_model
            orientation: ListView.Horizontal
            height: toolbar_row.height

            anchors {
                left: tweet_dialog_button.right
                leftMargin: 30 /* XXX */
                right: menu_button.left
            }

            spacing: 0
            interactive: false

            delegate: AccountDelegate {}
        }
        Button {
            id: menu_button
            button_text: "+"
            width: 25
            height: toolbar_row.height
            //anchors.left: account_view.right
            anchors.right: parent.right
            anchors.top: toolbar_row.top

            border {
                width: toolbar_row.border.width
                color: toolbar_row.border.color
            }
            onButtonClicked: {
                if (tweethon_menu.state == "hidden")
                    tweethon_menu.state = "main_menu"
                else
                    tweethon_menu.state = "hidden"
            }
        }
    }




    ListModel {
        id: tweet_panel_model
/*
        ListElement {
            type: "friends"
            screen_name: "boringplanet"
            uuid: ""
            args: ""
        }
        ListElement {
            type: "friends"
            account: "boringplanet"
        }
        ListElement {
            type: "friends"
            account: "boringplanet"
        }*/

    }

    ListModel {
        id: account_model
/*
        ListElement {
            uuid: "abcd"
            oauth: "abcde"
            screen_name: "boringplanet"
            avatar: "m00n_s.png"
            active: false
        }*/
/*
        ListElement {
            uuid: ""
            oauth: "abcde"
            screen_name: "tweethon_test"
            avatar: "m00n_s.png"
            active: false
        }*/


    }

    ListModel {
        id: panel_model

        ListElement {
            type: 'timeline'
        }
        ListElement {
            type: 'mentions'
        }
    }

    TweetDialog {
        id: twitter_dialog
        opacity: 0
        anchors.bottom: toolbar_row.top
        anchors.left: parent.left
        anchors.margins: 1
    }

    TweethonMenu {
        id: tweethon_menu

        accountModel: account_model
        panelModel: panel_model

        onAddAccount: {
            new_account_dialog.state = 'open';
        }

        onAddPanel: {
            twitter.subscribe({
                'uuid': tweethon_menu.for_account,
                'type': tweethon_menu.panel_type,
                'args': null,
            });
        }
    }

    NewAccoutDialog {
        id: new_account_dialog
        anchors.centerIn: parent

        onStateChanged: {
            if (state == 'open') {
                new_account_dialog.init();
            }
        }
    }

    Component.onCompleted: {
        /*
        app.backendReady.connect(function () {
            console.log("Backend ready");
            guiReady();
        })*/
        //account_model.changeEntry("uuid", "abcd", "screen_name", "itworks");
        twitter.announceAccount.connect(function (data) {
            account_model.append(data);
            console.log(data);
        })
        twitter.accountConnected.connect(function (data) {
            console.log("accountConnected " + data.screen_name);
            var keys = ['screen_name', 'avatar', 'connected'];
            for (var index in keys) {
                console.log(data.uuid + " " + keys[index] + " " + data[keys[index]]);
                Tweethon.changeEntry(account_model, "uuid", data.uuid, keys[index], data[keys[index]]);
            }
            Tweethon.changeEntry(tweet_panel_model, "uuid", data.uuid, "screen_name", data.screen_name);
        })
        twitter.newSubscription.connect(function (data) {
            console.log("newSubscription");
            tweet_panel_model.append(data);
        })
    }
}
