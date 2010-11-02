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
    var index_found = -1;
    each(tweet_store, function (index, panel) {
        if (panel.account == account && panel.type == type && panel.args == args) {
            each(tweet_store.tweets, function (index, tweet) {
                to_model.append(tweet);
            });
            index_found = index;
        }
    });

    if (index_found > -1) {
        tweet_store.splice(index_found, 1);
    }
    return index_found
}

function storeTweets (account, type, args, from_model) {
    var tweets = [];
    for (var i = 0; i < from_model.count; i++) {
        tweets.push(from_model.get(index));
    }

    var panel_data = {
        "account": account,
        "type": type,
        "args": args,
        "tweets": tweets
    };
    tweet_store.push(panel_data);

}

var tweet_store = [
    /*
    {
        "account": 0,
        "type": 0,
        "args": 0,
        "tweets": 0,
    }
    */
]
