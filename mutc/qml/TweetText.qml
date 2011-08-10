import QtQuick 1.0

Item {
    id: container

    width: 300
    height: 62

    Style { id: style }

    signal linkActivated(string link)
    property alias text: tweet_text.text
    property variant _indexmap

    Item {
        id: tweet_text

        anchors.fill: parent

        // ??
        property string text: "&gt;&lt; foo #bar @zort baz http://foo.bar/baz foo"


        TextEdit {
            id: text_storage
            text: tweet_text.text
            //textFormat: Text.PlainText
            visible: false
            width: parent.width
            height: parent.height

            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        Text {
            id: text_display
            z: 5
            width: parent.width
            height: parent.height

            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            //textFormat: Text.StyledText

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
                            container.linkActivated(item.url)
                        }
                    }
                }

                onMousePositionChanged: {
                    var textpos = text_storage.positionAt(mouse.x, mouse.y)
                    var array_position = container._indexmap[textpos]
                    //console.log(textpos, array_position)
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
            text_display.text = "<html><head></head><body>" + tokens.join(" ") + "</body></html>"
        }

        Component.onCompleted: {
            var splitted = text.split(" ")
            var unescaped_splitted = text.replace(/&([^\s]+?);/g, 'X').split(" ")
            //console.log(text.replace(/&([^ ;]+;)/g, "x"))
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

                //if (part.substr(0, 1) == "&")

                for (var ix = text_index; ix < text_index + unescaped_splitted[i].length; ix++) {
                    indexmap[ix] = i
                }
                indexmap[ix] = -1
                text_index += unescaped_splitted[i].length + 1

                model.append({"part": part, "islink": islink, "url": url})
            }
            container._indexmap = indexmap

            renderText(-1)
        }
    }
}
