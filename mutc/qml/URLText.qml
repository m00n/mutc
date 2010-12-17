import Qt 4.7


Item {
    id: container

    signal linkActivated(string link)

    property string text: ""
    property alias wrapMode: text_item.wrapMode
    property alias elide: text_item.elide
    property alias horizontalAlignment: text_item.horizontalAlignment
    property bool escapeUrls: true

    height: 22

    Text {
        id: text_item
        color: "white"
        anchors.fill: parent

        function setText(txt) {
            var css = '<style type="text/css">\n' +
                      'a:hover { color: #ff0000; }\n' +
                      'a:link{ color: ' + color + '; }\n' +
                      '</style>\n'

            container.text = txt;
            if (escapeUrls)
                text_item.text = css + txt.replace(/(http:\/\/\S*)/g, '<a href="$1">$1<\/a>') //  style="font-style:normal;"
            else
                text_item.text = css + txt
        }

        Component.onCompleted: {
            setText(container.text);
        }
        onLinkActivated: {
            container.linkActivated(link)
        }
    }

    function setText (txt) { text_item.setText(txt) }
}
