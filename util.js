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
