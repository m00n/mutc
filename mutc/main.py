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

from functools import *
from itertools import *

from path import path

import sip

sip.setapi('QString', 2)
sip.setapi('QVariant', 2)
sip.setapi('QDateTime', 2)


from PyQt4.Qt import *

import sys
import threading

from time import sleep, strptime
from twitter import Account, async

import json

import tweepy

from tweetmodel import TweetModel

import datetime

if strptime("12", "%H"):
    """
    This seems to cure the AttributeError: _strptime_time bug which
    seems to be related to the use of strptime in a thread before it's there
    """
    pass


class TwitterThread(QThread):
    newTweets = pyqtSignal(object, object)

    def __init__(self, parent, subscriptions):
        QThread.__init__(self, parent)
        self.subscriptions = subscriptions
        self.subscriptions_lock = threading.Lock()

        self.ticks = 1
        self.tick_count = 60

        self.running = True
        self.force_check = threading.Event()

    def run(self):
        while self.running:
            with self.subscriptions_lock:
                for subscription in self.subscriptions.values():
                    tweets = subscription.update()

                    if tweets:
                        print "new_tweets", len(tweets), tweets[0]
                        self.newTweets.emit(subscription, tweets)

            for x in xrange(self.tick_count):
                sleep(self.ticks)
                if self.force_check.is_set():
                    self.force_check.clear()
                    break


class Subscription(object):
    subscription_type = "abstract"

    def __init__(self, account, args):
        self.account = account
        self.args = args
        self.last_tweet_id = None

    def __hash__(self):
        return hash((self.account.uuid, self.args, self.__class__.__name__))

    def get_stream(self):
        raise NotImplemented

    def get_stream_args(self):
        return {}

    def simplify(self, tweets):
        return tweets

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

        return self.simplify(tweets)

    def tweets_before(self, max_id):
        cursor_args = {
            "max_id": max_id
        }
        cursor_args.update(self.get_stream_args())
        cursor = tweepy.Cursor(
            self.get_stream(),
            **cursor_args
        )
        tweets = list(cursor.items(21))[1:]

        return tweets


class Timeline(Subscription):
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
        "timeline": Timeline,
        "mentions": Mentions,
        "search": Search,
    }[name](account, args)


class Twitter(QObject):
    newTweets = pyqtSignal("QVariant")
    newSubscription = pyqtSignal("QVariant")

    announceAccount = pyqtSignal("QVariant")
    accountConnected = pyqtSignal("QVariant")

    newTweetsForModel = pyqtSignal(TweetModel, list, int)

    test = pyqtSignal("QVariant")

    def __init__(self):
        QObject.__init__(self)

        self.models = {}

        self.accounts = {}
        self.ordered_accounts = []

        self.subscriptions = {}
        self.ordered_subscriptions = []

        self.thread = TwitterThread(self, self.subscriptions)
        self.thread.newTweets.connect(self.on_new_tweets)
        self.thread.start()

        self.newTweetsForModel.connect(
            lambda model, tweets, index: model.insertTweets(tweets, index)
        )

    def on_new_tweets(self, subscription, tweets):
        key = (subscription.account.uuid,
               subscription.subscription_type,
               subscription.args)

        model = self.models[key]
        model.insertTweets(tweets, 0)


    @pyqtSlot("QVariant")
    def subscribe(self, request):
        subscription = create_subscription(
            request["type"],
            self.accounts[request["uuid"]],
            request.get("args", "")
        )

        key = (
            request["uuid"],
            request["type"],
            request["args"],
        )

        self.models[key] = TweetModel(self)

        with self.thread.subscriptions_lock:
            self.subscriptions[key] = subscription
            self.ordered_subscriptions.append(subscription)

        if subscription.account.me:
            request['screen_name'] = subscription.account.me.screen_name
        else:
            request['screen_name'] = subscription.account.uuid[:4]

        self.newSubscription.emit(request)
        self.thread.force_check.set()

    @pyqtSlot("QVariant")
    @async
    def tweet(self, tweet):
        """
        {
            text:
            accounts: []
        }
        """
        for account in imap(self.account, tweet["accounts"]):
            account.api.update_status(tweet["text"], tweet["in_reply"])

    def announce_account(self, account):
        print account
        print account.simplify()
        self.announceAccount.emit(account.simplify())

    @pyqtSlot(result=QObject)
    def new_account(self):
        account = Account()
        account.ready.connect(partial(self.announce_account, account))
        self.add_account(account)
        return account

    def add_account(self, account):
        self.ordered_accounts.append(account)
        self.accounts[account.uuid] = account
        account.connected.connect(
            lambda account: self.accountConnected.emit(account.simplify())
        )

    @pyqtSlot("QVariant", result=QObject)
    def account(self, uuid):
        return self.accounts[uuid]

    @pyqtSlot("QVariant")
    def dismiss_account(self, uuid):
        account = self.accounts.pop(uuid)
        self.ordered_accounts.remove(account)

    @pyqtSlot("QVariant")
    @async
    def need_tweets(self, request):
        print "need_tweets", request
        key = (
            request["uuid"],
            request["type"],
            request["args"],
        )
        subscription = self.subscriptions[key]
        model = self.models[key]

        tweets = subscription.tweets_before(model.oldestId())
        self.newTweetsForModel.emit(model, tweets, -1)

    def start_sync(self):
        """
        Emit accounts & saved options to gui
        """
        for account in self.ordered_accounts:
            self.announceAccount.emit(account.simplify())
            account.connect()

    @pyqtSlot("QVariant", "QVariant", "QVariant", result=QObject)
    def get_model(self, uuid, panel_type, args):
        return self.models[uuid, panel_type, args]


class App(QApplication):
    backendReady = pyqtSignal()

    def __init__(self, args, twitter):
        QApplication.__init__(self, args)

        self.twitter = twitter

        self.data_path = path('~/.mutc').expand()

        if not self.data_path.exists():
            self.data_path.mkdir()

        self.aboutToQuit.connect(self._on_shutdown)

    def load_accounts(self):
        try:
            with open(self.data_path / 'accounts.json') as fd:
                accounts = json.load(fd)
        except IOError:
            pass
        else:
            for accout_data in accounts:
                self.twitter.add_account(Account(*accout_data))

    def _on_shutdown(self):
        self.twitter.thread.running = False
        self.twitter.thread = False
        accounts = []
        for account in self.twitter.ordered_accounts:
            accounts.append(
                (account.oauth_key, account.oauth_secret, account.uuid)
            )

        with open(self.data_path / 'accounts.json', 'w') as fd:
            json.dump(accounts, fd)


def main():
    twitter = Twitter()
    app = App(sys.argv, twitter)

    declarative_view = QDeclarativeView()
    declarative_view.setViewport(QGLWidget())
    declarative_view.setResizeMode(QDeclarativeView.SizeRootObjectToView)

    root_context = declarative_view.rootContext()
    root_context.setContextProperty('twitter', twitter)
    root_context.setContextProperty('app', app)

    declarative_view.setSource(
        QUrl.fromLocalFile(path(__file__).parent / "qml" / "main.qml")
    )

    root_object = declarative_view.rootObject()
    #root_object.coonect(root_object, SIGNAL('guiReady()'), )

    app.load_accounts()
    twitter.start_sync()

    declarative_view.show()

    return app.exec_()

if __name__ == '__main__':
    import sys
    sys.stdout = sys.stderr

    sys.exit(main())
