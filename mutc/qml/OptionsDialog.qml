import QtQuick 1.0

Rectangle {
    id: options_dialog

    width: 320
    height: 400

    color: style.backgroundColor

    Style { id: style }

    function show() {
        options_dialog.opacity = 1

        for (var i = 0; i < settings_column.children.length; i++) {
            var item = settings_column.children[i]
            if (item.configValue) {
                item.text = config.get(item.configValue)
            }
        }
    }

    Flickable {
        id: options_model

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: buttons.top
        }

        Rectangle {
            Column {
                id: settings_column

                spacing: 2
                anchors {
                    fill: parent
                    leftMargin: 5
                    rightMargin: 5
                }

                Text {
                    text: "Proxy"
                    height: 22
                    width:  310
                    horizontalAlignment: Text.AlignHCenter
                    color: style.textColor
                    font.bold: true
                }
                Text {
                    text: "Hostname"
                    width: 310
                    height: 22
                    color: style.textColor
                }
                BorderTextInput {
                    id: hostname_input

                    property string configValue: "proxy.host"
                    property string configType: "str"
                }

                Text {
                    text: "Port"
                    width: 310
                    height: 22
                    color: style.textColor
                }
                BorderTextInput {
                    id: port_input

                    property string configValue: "proxy.port"
                    property string configType: "int"
                }

                Text {
                    text: "API Calls"
                    color: style.textColor
                    font.bold:  true
                    width: 310
                    height: 30
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: "Clients"
                    width: 310
                    height: 22
                    color: style.textColor
                }
                BorderTextInput {
                    id: limits_client

                    property string configValue: "limits.clients"
                    property string configType: "int"
                }

                Text {
                    text: "Buffer"
                    width: 310
                    height: 22
                    color: style.textColor
                }
                BorderTextInput {
                    id: limits_buffer

                    property string configValue: "limits.buffer"
                    property string configType: "int"
                }
            }
        }
    }

    Item {
        id: buttons
        height: 22

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Button {
            id: save_button

            width: parent.width / 3
            height: 22

            button_text: "Save"
            anchors.right: parent.right

            onButtonClicked: {
                options_dialog.opacity = 0

                for (var i = 0; i < settings_column.children.length; i++) {
                    var item = settings_column.children[i]
                    if (item.configValue) {
                        console.log(item.configValue)

                        if (config) {
                            config.set(item.configValue, item.text)
                        }
                    }
                }
            }

        }
        Button {
            width: parent.width / 3
            height: 22

            button_text: "Cancel"
            anchors.right:  save_button.left

            onButtonClicked: {
                options_dialog.opacity = 0
            }
        }
    }


    Behavior on opacity {
        NumberAnimation {
            duration: 250
        }
    }

}
