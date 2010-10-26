import Qt 4.7


Item {
    id: container
    property string text: ""
    property alias wrapMode: text_item.wrapMode

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
            text_item.text = css + txt.replace(/(http:\/\/\S*)/g, '<a href="$1">$1<\/a>') //  style="font-style:normal;"
        }

        Component.onCompleted: {
            setText(container.text);
        }
    }
}
