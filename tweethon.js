function each(l, f) {
    for (var i = 0; i < l.length; i++) {
        f(i, l[i]);
    }
}

function changeEntry (model, id_field, id_value, ch_field, ch_value) {
    for (var i = 0; i < model.count; i ++) {
        var data = model.get(i);
        if (data[id_field] == id_value) {
            data[ch_field] = ch_value
        }
        model.set(i, data);
    }
}

function indexFor (model, id_field, id_value) {
    for (var i = 0; i < account_model.count; i ++) {
        var data = account_model.get(i);
        if (data[id_field] == id_value)
            return i
    }
}

function restoreTweets (account, type, args, to_model) {
    var tweets = tweet_store.load(
        {
            "account": account,
            "type": type,
            "args": args,
        }
    );
    if (tweets)
    {
        each(tweets, function (index, tweet) { to_model.append(tweet); });
    }
}

function storeTweets (account, type, args, from_model) {
    var panel_data = {
        "account": account,
        "type": type,
        "args": args,
        "tweets": [],
    };

    for (var i = 0; i < from_model.count; i++) {
        var model_object = from_model.get(i);
        var js_object = new Object();
        for (var attr in model_object) {
            js_object[attr] = model_object[attr];
        }
        panel_data.tweets.push(js_object);
    }
    tweet_store.store(panel_data);

}
