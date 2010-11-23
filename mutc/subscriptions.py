#!/usr/bin/env python
# -*- coding: utf-8 -*-

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
# or visit http://www.gnu.org/licenses/licenses.html#GPL

from __future__ import with_statement, division

from collections import OrderedDict

import tweepy
from PyQt4.Qt import *

class Subscription(QObject):
    subscription_type = "abstract"

    newTweetsReceived = pyqtSignal(object, object)
    oldTweetsReceived = pyqtSignal(object, object)

    def __init__(self, account, args):
        QObject.__init__(self)

        self.account = account
        self.args = args
        self.last_tweet_id = None

        self.fetching = False

    def __hash__(self):
        return hash((self.account.uuid, self.args, self.__class__.__name__))

    def __repr__(self):
        return "<Subscription(%r, %r, %r)>" % (
            self.account.uuid[:8],
            self.subscription_type,
            self.args
        )

    def get_stream(self):
        raise NotImplementedError

    def get_stream_args(self):
        return {}

    def update(self):
        tweets = []

        cursor_args = {}
        count = None

        if self.last_tweet_id:
            cursor_args["since_id"] = self.last_tweet_id
        else:
            count = 20

        cursor_args.update(self.get_stream_args())

        cursor = tweepy.Cursor(
            self.get_stream(),
            **cursor_args
        )

        for status in cursor.items(count):
            tweets.append(status)

        if tweets:
            self.last_tweet_id = tweets[0].id
            self.newTweetsReceived.emit(self, tweets)

        return tweets

    def tweets_before(self, max_id):
        self.fetching = True

        cursor_args = {
            "max_id": max_id
        }
        cursor_args.update(self.get_stream_args())
        cursor = tweepy.Cursor(
            self.get_stream(),
            **cursor_args
        )
        tweets = list(cursor.items(21))[1:]

        self.fetching = False
        self.oldTweetsReceived.emit(self, tweets)

        return tweets

    def key(self):
        return (
            self.account.uuid,
            self.subscription_type,
            self.args
        )


class FriendsTimeline(Subscription):
    def get_stream(self):
        return self.account.api.friends_timeline

class RetweetsTimeline(Subscription):
    def get_stream(self):
        return self.account.api.retweeted_to_me

class HomeTimeline(Subscription):
    subscription_type = "timeline"
    def get_stream(self):
        return self.account.api.home_timeline

class Mentions(Subscription):
    subscription_type = "mentions"
    def get_stream(self):
        return self.account.api.mentions

class Search(Subscription):
    subscription_type = "search"
    def get_stream(self):
        return self.account.api.search

    def get_stream_args(self):
        return {'q': self.args}


def create_subscription(name, account, args):
    return {
        "timeline": HomeTimeline,
        "mentions": Mentions,
        "search": Search,
    }[name](account, args)


class Subscriptions(QAbstractListModel):
    def __init__(self):
        self.types = OrderedDict()

    def register(self, subscription_class):
        self.types[subscription_class.subscription_type] = subscription_class

    def rowCount(self, parent=None):
        return len(self.types)

    def data(self, index, role):
        pass


#subscriptions = Subscriptions()
#subscriptions.register(HomeTimeline)
#subscriptions.register(Mentions)
#subscriptions.register(Search)
