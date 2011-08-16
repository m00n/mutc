import Qt 4.7

ListModel {
    id: dummy_tweets

    ListElement {
        created_at: "13:37"
        message: "@foobar #z http://abcd.de/ Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor"
        is_retweet: true
        retweet_by: "lorem"
        in_reply: "ipsum"
        in_reply_id: "1111111111111"
        my_favorite: false
    }

    ListElement {
        created_at: "13:37"
        message: "&lt; &gt; &lt;3 #foo Lorem &ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor"
        is_retweet: true
        retweet_by: "lorem"
        my_favorite: false
    }

    ListElement {
        created_at: "13:37"
        message: "Lorem ipsum dolor sit amet, http://foo.de/zort/123 consectetur adipisicing elit, sed do eiusmod tempor"
        is_retweet: true
        retweet_by: "lorem"
        my_favorite: false
    }

    ListElement {
        created_at: "13:37"
        message: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor"
        is_retweet: true
        retweet_by: "lorem"
        my_favorite: true
    }

    ListElement {
        created_at: "13:37"
        message: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor"
        is_retweet: true
        retweet_by: "lorem"
        my_favorite: false
    }

    ListElement {
        created_at: "13:37"
        message: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor"
        is_retweet: true
        retweet_by: "lorem"
        my_favorite: false
    }

    ListElement {
        created_at: "13:37"
        message: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor"
        is_retweet: true
        retweet_by: "lorem"
        my_favorite: false
    }

    Component.onCompleted: {
        for (var i = 0; i < dummy_tweets.count; i++) {
            var d = dummy_tweets.get(i);
            d["author"] = {
                "screen_name": "test",
                "profile_image_url": "../../m00n_s.png"
            }
            dummy_tweets.set(i, d);
        }
    }
}
