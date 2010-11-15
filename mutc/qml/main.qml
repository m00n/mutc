import Qt 4.7

import "util.js" as Utils

Rectangle {
    id: main_window

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

            model: twitter.get_model(uuid, type, args)

            onNeedTweets: {
                twitter.need_tweets({
                    "uuid": uuid,
                    "type": type,
                    "args": args,
                });
            }
        }
        width: parent.width

        anchors.top: main_window.top
        anchors.bottom: toolbar_row.top

        spacing: 10
    }

    Toolbar {
        id: toolbar_row
        height: 22
        anchors.bottom: main_window.bottom
        anchors.left: main_window.left

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
                if (main_menu.state == "hidden")
                    main_menu.state = "main_menu"
                else
                    main_menu.state = "hidden"
            }
        }
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
            args: false
            ask_text: ""
        }
        ListElement {
            type: 'mentions'
            args: false
            ask_text: ""
        }
        ListElement {
            type: 'search'
            args: true
            ask_text: "Enter search query"
        }
    }

    TweetDialog {
        id: twitter_dialog
        opacity: 0
        anchors.bottom: toolbar_row.top
        anchors.left: parent.left
        anchors.margins: 1
    }

    MainMenu {
        id: main_menu

        accountModel: account_model
        panelModel: panel_model

        onAddAccount: {
            new_account_dialog.state = 'open';
        }

        onAddPanel: {
            twitter.subscribe({
                'uuid': main_menu.for_account,
                'type': main_menu.panel_type,
                'args': "",
            });
        }
        onNeedArgs: {
            search_dialog.text = main_menu.need_args
            search_dialog.state = "visible"
        }
        Component.onCompleted: {
            search_dialog.dialogAccepted.connect(function () {
                twitter.subscribe({
                    'uuid': main_menu.for_account,
                    'type': main_menu.panel_type,
                    'args': search_dialog.value,
                })
            })
        }
    }

    InputDialog {
        id: search_dialog
        text: ""
        state: "hidden"

        onDialogAccepted: {
            console.log(value);
        }

        anchors.centerIn: main_window
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
                Utils.changeEntry(account_model, "uuid", data.uuid, keys[index], data[keys[index]]);
            }
            Utils.changeEntry(tweet_panel_model, "uuid", data.uuid, "screen_name", data.screen_name);
        })
        /*
        twitter.newSubscription.connect(function (data) {
            console.log("newSubscription" + data.args);
            tweet_panel_model.append(data);
        })*/
    }
}