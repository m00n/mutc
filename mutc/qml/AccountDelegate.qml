import Qt 4.7

Component {
    id: account_delegate

    Rectangle {
        height: 22
        width: (screen_name_text.paintedWidth) + 23

        color: "#00000000"

        Rectangle {
            id: highlight_rectangle

            opacity: active ? 1.0 : 0.0
            x: avatar_border.x
            y: avatar_border.y + 1
            width: avatar_border.width + screen_name_text.width + 3
            height: avatar_border.height - 3
            color: "steelblue"
            z: -1
            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }

        }

        Rectangle {
            opacity: mouse_area.containsMouse ? 1.0 : 0.0
            color: "#00000000"

            anchors.fill: highlight_rectangle

            border {
                color: "steelblue"
                width: 1
            }

            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }

        Rectangle {
            id: avatar_border

            height: 22
            width: 22

            color: "#00000000"

            Image {
                id: avatar_image
                source: avatar

                fillMode: Image.PreserveAspectFit
                smooth: true

                anchors.fill: parent
                anchors.margins: 2
            }
            anchors {
                top: parent.top
                right: screen_name_text.left
                leftMargin: 5
            }
        }

        Text {
            id: screen_name_text
            text: screen_name
            color: "white"

            anchors {
                left: avatar.right
                leftMargin: 5
                verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: mouse_area

            height: 22

            anchors.left: avatar_border.left
            anchors.right: screen_name_text.right

            hoverEnabled: true

            z: 100
            onClicked: {
                var coords = ListView.view.mapFromItem(screen_name_text, mouseX, mouseY);
                var idx = ListView.view.indexAt(coords.x, coords.y);
                var data = account_model.get(idx);
                data.active = !data.active;
                ListView.view.model.set(idx, data);
            }
        }
    }
}
