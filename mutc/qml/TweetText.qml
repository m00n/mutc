import QtQuick 1.0

Item {
    id: container

    width: 100
    height: 62

    Style { id: style }

    property alias text: tweet_text.text
    property variant _indexmap

    Item {
        id: tweet_text

        anchors.fill: parent

        property string text: "foo #bar @zort baz http://foo.bar/baz foo"
        signal linkActivated(string url)

        TextEdit {
            id: text_storage
            text: tweet_text.text
            textFormat: Text.StyledText
            visible: false
            width: parent.width
            height: parent.height

            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        Text {
            id: text_display

            width: parent.width
            height: parent.height

            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            textFormat: Text.StyledText

            color: style.textColor

            MouseArea {
                width: parent.width
                height: parent.height

                hoverEnabled: true

                onExited: {
                    tweet_text.renderText(-1)
                }

                onClicked: {
                    var textpos = text_storage.positionAt(mouse.x, mouse.y)
                    var array_position = container._indexmap[textpos]
                    if (array_position > -1) {
                        var item = model.get(array_position)

                        if (item.islink) {
                            tweet_text.linkActivated(item.url)
                        }
                    }
                }

                onMousePositionChanged: {
                    var textpos = text_storage.positionAt(mouse.x, mouse.y)
                    var array_position = container._indexmap[textpos]

                    if (array_position > -1 && model.get(array_position).islink)
                        tweet_text.renderText(array_position)
                    else
                        tweet_text.renderText(-1)
                }
            }
        }

        ListModel {
            id: model
        }

        function renderText(highlight_index) {
            var tokens = [];
            for (var i = 0; i < model.count; i++) {
                var text_part = model.get(i)

                if (i == highlight_index)
                    tokens.push("<u>" + text_part.part + "</u>")
                else
                    tokens.push(text_part.part)
            }
            text_display.text = tokens.join(" ")
        }

        Component.onCompleted: {
            var splitted = text.split(" ")

            var indexmap = {}
            var text_index = 0
            for (var i = 0; i < splitted.length; i++) {
                var part = splitted[i]
                var url = null
                var islink = false


                if (part.substr(0, 1) == "@") {
                    url = "http://twitter.com/" + part.substr(1)
                    islink = true
                } else if (part.substr(0, 1) == "#") {
                    url = "search://" + part.substr(1)
                    islink = true
                } else if (part.match(/(http:\/\/\S*)/g)) {
                    url = part
                    islink = true
                }
                for (var ix = text_index; ix < text_index + part.length; ix++) {
                    indexmap[ix] = i
                }
                indexmap[ix] = -1
                text_index += part.length + 1

                model.append({"part": part, "islink": islink, "url": url})
            }
            container._indexmap = indexmap

            /*for (var i in container._indexmap) {
                console.log(i, "->", container._indexmap[i])
            }*/

            renderText(-1)
        }
    }
}
