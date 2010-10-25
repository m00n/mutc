import Qt 4.7
import "tweethon.js" as Tweethon

Rectangle {
    id: tweet_panel
    width: 320
    height: 480
    //color: "red"

    property int max_tweets: 30
    property string account: "no account"
    property string account_oid: "no oid"
    property string panel_type: "timeline"
    /*
        "friends"
        "mentions"
        "search"
    */

    signal needTweets

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

    //spacing: 2
    //id: tweet_column

    //anchors.fill: parent
    Toolbar {
        id: title_rect
        anchors.top: parent.top
        height: 22

        Text {
            x: 5
            text: "@" + account.name
            color: "white"
            //width: tweet_panel.width
            anchors.verticalCenter: parent.verticalCenter
            MouseArea {
                anchors.fill: parent
                onClicked: { addTweet({}) }
            }

        }
        z: 1
    }

    ListView {
        model: tweet_model
        //anchors.fill: parent
        //width: parent.width
        //height: parent.height
        //anchors.top: title_rect.bottom
        //anchors.bottom:
        anchors {
            top: title_rect.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        spacing: 2
        delegate: TweetDelegate {
            width: {
                if (parent)
                    parent.width
                else
                    300
            }
        }
        onFlickEnded: {
            if (parent.atYEnd) {
                needTweets({
                    "account": account,
                    "type": type,
                    "since": tweet_model.get(tweet_model.count).tweet_id
                });
            }
        }
    }



    ListModel {
        id: tweet_model
        ListElement {
            author: "boringplanet"
            tweet_text: "Faketweet test das ist ein test blablubb foo bar baz bazinga zort hoot hoot hoot"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
        ListElement {
            author: "boringplanet a"
            tweet_text: "Faketweet 2"
            avatar: "m00n_s.png"
        }
    }

    function foo() {
        console.log('bar');
    }
    function bar(pyobj) {
        console.log(pyobj)
        console.log(pyobj.a)
    }

    function addTweet(tweet) {
    }


    Component.onCompleted: {
        console.log("Panel");
        //console.log("> " + pyobj.get_foo() + "<");
        //console.log("> " + zort() + "<");
    }
}
