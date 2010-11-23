import Qt 4.7

ListModel {
    id: dummy_tweets

    ListElement {
        //author: {"screen_name": "test"}
        created_at: "13:37"
        message: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor"
        is_retweet: true
        retweet_by: "lorem"
    }
    ListElement {
        //author: {"screen_name": "test"}
        created_at: "13:37"
        message: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor"
        is_retweet: true
        retweet_by: "lorem"
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
