import Qt 4.7

Rectangle {
    id: tweethon_menu
    opacity: 0

    width: 320
    height: 240

    color: "#323436"
    state: "hidden"

    signal addAccount
    signal addPanel

    property alias accountModel: account_menu_view.model
    property alias panelModel: panel_view.model

    property alias for_account: panel_view.for_account
    property alias panel_type: panel_view.panel_type

    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }

    TitleBar {
        id: title
        text: "Tweethon menu"
        color: border.color
    }
    Button {
        id: add_account_button
        button_text: "Add account"
        height: 22
        width: parent.width
        border {
            width: title.border.width
            color: title.border.color
        }
        anchors {
            top: title.bottom
            left: parent.left
            right: parent.right
            topMargin: 5
        }
        onButtonClicked: {
            //new_account_dialog.state = 'open';
            addAccount()
            tweethon_menu.state = 'hidden';
        }
    }

    ListView {
        id: account_menu_view

        //model: account_model

        delegate: Button {
            button_text: "Create panel for `" + screen_name + "` >"
            height: 22
            width: 320
            border {
                width: title.border.width
                color: title.border.color
            }
            onButtonClicked: {
                panel_view.for_account = uuid
                tweethon_menu.state = "panel_menu"
            }
        }

        anchors {
            top: add_account_button.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            topMargin: 5
        }
    }

    ListView {
        id: panel_view
        model: panel_model

        property string for_account
        property string panel_type

        delegate: Button {
            button_text: type
            height: 22
            width: 320

            border {
                width: title.border.width
                color: title.border.color
            }

            onButtonClicked: {
                tweethon_menu.state = "hidden";
                panel_view.panel_type = type;

                addPanel();
            }
        }
        anchors {
            top: add_account_button.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            topMargin: 5
        }
    }

    anchors {
        bottom: toolbar_row.top
        right: parent.right
    }

    states: [
        State {
            name: "main_menu"
            PropertyChanges {
                target: account_menu_view
                opacity: 1
            }
            PropertyChanges {
                target: panel_view
                opacity: 0
            }
            PropertyChanges {
                target: tweethon_menu
                opacity: 1
            }
        },
        State {
            name: "panel_menu"
            PropertyChanges {
                target: account_menu_view
                opacity: 0
            }
            PropertyChanges {
                target: panel_view
                opacity: 1
            }
            PropertyChanges {
                target: tweethon_menu
                opacity: 1
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: tweethon_menu
                opacity: 0
            }
        }

    ]

    transitions: [
        Transition {
            NumberAnimation { property: "opacity"; duration: 250 }
        }
    ]
}
