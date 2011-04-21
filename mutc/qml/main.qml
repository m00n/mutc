import Qt 4.7

import "util.js" as Utils

Rectangle {
    id: main_window

    width: 320
    height: 480

    property bool locked: false

    signal guiReady

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

    ListView {
        id: tweet_panels
        model: tweet_panel_model
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        interactive: !locked
        keyNavigationWraps: true

        function scrollToLast() {
            tweet_panels.positionViewAtIndex(tweet_panel_model.count - 1, ListView.End)
        }

        delegate: TweetPanel {
            id: tweet_panel

            width: type == "wall" ? 640 : 320

            locked: main_window.locked

            anchors.top: { if (parent) parent.top }
            anchors.bottom: { if (parent) parent.bottom }

            model: twitter.get_model(uuid, type, args)

            onNeedTweets: {
                twitter.get_model(uuid, type, args).needTweets()
            }

            onReply: {
                var model = twitter.get_model(uuid, type, args)
                var tweet = model.get(tweet_panel.tweetView.currentIndex)

                twitter_dialog.state = "visible"

                if (model.type != "direct messages") {
                    twitter_dialog.in_reply_id = tweet.tweet_id
                    twitter_dialog.text = "@" + tweet.author.screen_name + " "
                    twitter_dialog.edit.cursorPosition = twitter_dialog.text.length
                } else {
                    twitter_dialog.in_reply_id = tweet.author.id_str
                    twitter_dialog.in_reply = tweet.author.screen_name
                    twitter_dialog.direct_message_from = uuid
                    twitter_dialog.direct_message = true
                }
            }

            onRetweet: {
                var model = twitter.get_model(uuid, type, args)
                var tweet = model.get(tweet_panel.tweetView.currentIndex)

                if (model.type != "direct messages") {
                    if (comment) {
                        twitter_dialog.state = "visible"
                        twitter_dialog.text = "RT @" + tweet.author.screen_name + ": " + tweet.message
                        twitter_dialog.in_reply = tweet.tweet_id
                        twitter_dialog.edit.cursorPosition = 0
                    } else {
                        twitter.retweet(account_model.getActiveAccounts(), tweet.tweet_id);
                    }
                } else {
                    status_dialog.show("Error", "Can't retweet direct messages")
                    main_window.locked = false
                }
            }

            onUndoRetweet: {
                var model = twitter.get_model(uuid, type, args)
                var tweet = model.get(tweet_panel.tweetView.currentIndex)
                twitter.undo_retweet(account_model.getActiveAccounts(), tweet.tweet_id)
            }

            onRemoveTweet: {
                var model = twitter.get_model(uuid, type, args)
                var tweet = model.get(tweet_panel.tweetView.currentIndex)
                if (model.type != "direct messages") {
                    twitter.destroy_tweet(tweet.tweet_id)
                } else {
                    twitter.destroy_direct_message(uuid, tweet.tweet_id)
                }
            }

            onPanelsLocked: {
                main_window.locked = true
            }

            Component.onCompleted: {
                main_window.lockedChanged.connect(lockCallback)
            }
            Component.onDestruction: {
                main_window.lockedChanged.disconnect(lockCallback)
            }

            function lockCallback () {
                tweet_panel.locked = main_window.locked
                if (tweet_panel.overlay && !main_window.locked)
                    tweet_panel.overlay = false
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
                if (twitter_dialog.state == "visible")
                    twitter_dialog.state = "hidden";
                else if (twitter_dialog.state == "hidden")
                    twitter_dialog.state = "visible";
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

        function getActiveAccounts() {
            var accounts = [];
            for (var i = 0; i < account_model.count; i ++) {
                var account = account_model.get(i)
                if (account.active)
                    accounts.push(account.uuid)
            }

            return accounts
        }
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
            type: 'direct messages'
            args: false
            ask_text: ""
        }
        ListElement {
            type: 'search'
            args: true
            ask_text: "Enter search query"
        }
        ListElement {
            type: 'wall'
            args: true
            ask_text: "Enter hashtag"
        }
    }

    TweetDialog {
        id: twitter_dialog
        state: "hidden"
        anchors.bottom: toolbar_row.top
        anchors.left: parent.left
        anchors.margins: 1

        onSendClicked: {
            main_window.locked = true
            if (!direct_message) {
                twitter.tweet(account_model.getActiveAccounts(), twitter_dialog.text, in_reply_id)
            } else {
                twitter.send_direct_message(direct_message_from, in_reply_id, twitter_dialog.text)
            }
        }

        onStateChanged: {
            if (state == "visible")
                twitter_dialog.edit.focus = true
        }
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
        onOptionsButtonClicked: {
            options_dialog.show()
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
        anchors.centerIn: main_window

        onDialogAccepted: {
            console.log(value);
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

        onAuthFailed: {
            console.log("authfailed");
            status_dialog.show("Account", "Authentication failed - please try again");
        }

        onAuthSuccessful: {
            status_dialog.show("Account", "Account successfully authenticated")
        }
    }

    Dialog {
        id: status_dialog
        text: ""
        title: ""
        state: "hidden"

        anchors.centerIn: parent

        function show(title, msg) {
            status_dialog.text = msg
            status_dialog.title = title
            status_dialog.state = "visible"
        }
    }

    OptionsDialog {
        id: options_dialog
        opacity: 0
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: toolbar_row.top
            bottomMargin: 2
        }
    }

    focus: true

    Keys.onReleased: {
        if (main_menu.state == "hidden" && twitter_dialog.state == "hidden") {
            if (event.key == Qt.Key_Left) {
                if (tweet_panels.currentItem.overlay) {
                    var view = tweet_panels.currentItem.tweetView
                    if (view.currentOverlayIndex > 0)
                        view.currentOverlayIndex--
                } else {
                    tweet_panels.decrementCurrentIndex()
                }

            }
            if (event.key == Qt.Key_Right) {
                if (tweet_panels.currentItem.overlay) {
                    var view = tweet_panels.currentItem.tweetView
                    if (view.currentOverlayIndex + 1 < view.overlayItemCount)
                        view.currentOverlayIndex++
                } else {
                    tweet_panels.incrementCurrentIndex()
                }
            }
            if (event.key == Qt.Key_Down) {
                var view = tweet_panels.currentItem.tweetView
                if (view.currentIndex + 1 == view.model.count) {
                    if (!view.model.busy) {
                        tweet_panels.currentItem.needTweets()
                        view.positionViewAtIndex(view.model.count - 1, ListView.Beginning)
                    }
                } else {
                    view.incrementCurrentIndex()
                }
            }
            if (event.key == Qt.Key_Up) {
                tweet_panels.currentItem.tweetView.decrementCurrentIndex()
            }
            if (event.key == Qt.Key_Home) {
                tweet_panels.currentItem.tweetView.currentIndex = 0
            }
            if (event.key == Qt.Key_End) {
                var view = tweet_panels.currentItem.tweetView
                view.currentIndex = view.model.count - 1
            }
            if (event.key == Qt.Key_T) {
                twitter_dialog.state = "visible"
            }
            if (event.key == Qt.Key_M) {
                main_menu.state = "main_menu"
            }
            if (event.key == Qt.Key_Space) {
                tweet_panels.currentItem.overlay = !tweet_panels.currentItem.overlay
            }
        }

        if (event.key == Qt.Key_Return) {
            if (twitter_dialog.state == "visible") {
                twitter_dialog.sendClicked()
            }

            if (twitter_dialog.state != "visible" && tweet_panels.currentItem.overlay) {
                var view = tweet_panels.currentItem.tweetView
                view.emulateClick()
            }
        }
        if (event.key == Qt.Key_Escape) {
            twitter_dialog.state = "hidden"
            main_menu.state = "hidden"
        }
    }

    function incCurrentIndex(view) {
        if (view.currentIndex + 1 == view.model.count)
            view.currentIndex = 0
        else
            view.currentIndex++
    }

    function decCurrentIndex(view) {
        if (view.currentIndex - 1 < 0)
            view.currentIndex = view.model.count - 1
        else
            view.currentIndex--
    }

    Component.onCompleted: {
        twitter.announceAccount.connect(function (data) {
            account_model.append(data);
            console.log("announceAccount", data);
        })
        twitter.accountConnected.connect(function (data) {
            console.log("accountConnected " + data.screen_name);
            var keys = ['screen_name', 'avatar', 'connected'];
            for (var index in keys) {
                Utils.changeEntry(account_model, "uuid", data.uuid, keys[index], data[keys[index]]);
            }
            //Utils.changeEntry(tweet_panel_model, "uuid", data.uuid, "screen_name", data.screen_name);
        })
        twitter.requestSent.connect(function (success, error_msg) {
            main_window.locked = false
            twitter_dialog.state = "hidden"

            if (!success) {
                status_dialog.show("Request failed", error_msg)
            }
        })
        tweet_panel_model.countChanged.connect(function (count, old_count) {
            if (count > old_count) {
                console.log(count + " " + old_count)
                tweet_panels.scrollToLast()
            }

        })
    }
}
