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

from time import sleep
from twitter import Account, async

import json

import tweepy

def pick(dictionary, *keys):
    return dict((key, getattr(dictionary, key)) for key in keys)

def status_to_dict(status):
    is_rt = hasattr(status, "retweeted_status")
    retweeted_status = getattr(status, "retweeted_status", None)

    return {
        "author": author_to_dict(status.author),
        "message": status.text[3:] if is_rt else status.text,
        "created_at": format_datetime(status.created_at),
        "id": status.id_str,
        "is_rt": is_rt,
        "rt_from": retweeted_status.author.screen_name if is_rt else None,
    }

def author_to_dict(user):
    return pick(
        user,
        "screen_name",
        "name",
        "description",
        "profile_image_url"
    )

def search_to_dict(searchresult):
    return {
        "author": searchresult.from_user,
        "text": searchresult.text,
        "created_at": status.created_at,
        "id": searchresult.id_str
    }


class TwitterThread(QThread):
    newTweets = pyqtSignal("QVariant")

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
                for subscription in self.subscriptions:
                    tweets = subscription.update()

                    if tweets:
                        print "new_tweets", len(tweets), tweets[0]
                        self.newTweets.emit({
                            "uuid": subscription.account.uuid,
                            "type": subscription.subscription_type,
                            "args": subscription.args,
                            "insert": "top",
                            "tweets": tweets
                        })

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

    def get_stream(self):
        raise NotImplemented

    def get_stream_args(self):
        return {}

    def simplify(self, tweets):
        raise NotImplemented

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
            #print status, repr(status.text)
            tweets.append(status)

            #if self.last_tweet_id and self.last_tweet_id == status.id:
                #break

        if tweets:
            self.last_tweet_id = tweets[0].id

        return self.simplify(tweets)


class TimelineBase(Subscription):
    def simplify(self, tweets):
        return map(status_to_dict, tweets)


class Timeline(TimelineBase):
    subscription_type = "timeline"
    def get_stream(self):
        return self.account.api.friends_timeline


class Mentions(TimelineBase):
    subscription_type = "mentions"
    def get_stream(self):
        return self.account.api.mentions


class Search(Subscription):
    subscription_type = "search"

    def simplify(self, searches):
        return map(search_to_dict, searches)

    def get_stream(self):
        return self.account.api.search

    def get_stream_args(self):
        return {'q': self.args[0]}


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

    def __init__(self):
        QObject.__init__(self)

        self.accounts = {}
        self.ordered_accounts = []
        self.subscriptions = set()

        self.thread = TwitterThread(self, self.subscriptions)
        self.thread.newTweets.connect(self.newTweets.emit)
        self.thread.start()

    @pyqtSlot("QVariant")
    def subscribe(self, subscription):
        print subscription
        account = self.accounts[subscription["uuid"]]

        if account.me:
            subscription['screen_name'] = account.me.screen_name
        else:
            subscription['screen_name'] = account.uuid[:4]

        self.newSubscription.emit(subscription)

        # XXX
        subscription = create_subscription(
            subscription["type"],
            account,
            subscription.get("args", ())
        )
        with self.thread.subscriptions_lock:
            self.subscriptions.add(subscription)

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
        print self.accounts
        account = self.accounts.pop(uuid)
        self.ordered_accounts.remove(account)

    @pyqtSlot("QVariant")
    @async
    def need_tweets(self, request):
        print "need_tweets", request

        account = self.accounts[request["uuid"]]
        subscription = create_subscription(request["type"], account, None)
        cursor = tweepy.Cursor(
            subscription.get_stream(),
            max_id=request["before"]
        )

        tweets = map(status_to_dict, cursor.items(20))[1:]

        self.newTweets.emit({
            "uuid": subscription.account.uuid,
            "type": subscription.subscription_type,
            "args": subscription.args,
            "insert": "bottom",
            "tweets": tweets
        })

    def start_sync(self):
        """
        Emit accounts & saved options to gui
        """
        for account in self.ordered_accounts:
            self.announceAccount.emit(account.simplify())
            account.connect()


class Tweethon(QApplication):
    backendReady = pyqtSignal()

    def __init__(self, args, twitter):
        QApplication.__init__(self, args)

        self.twitter = twitter

        self.data_path = path('~/.tweethon').expand()

        #self.load_accounts()

        self.aboutToQuit.connect(self._stop_tweethon)


    def load_accounts(self):
        try:
            with open(self.data_path / 'accounts.json') as fd:
                accounts = json.load(fd)
        except IOError:
            pass
        else:
            for accout_data in accounts:
                self.twitter.add_account(Account(*accout_data))

    def _stop_tweethon(self):
        self.twitter.thread.running = False
        self.twitter.thread = False
        accounts = []
        for account in self.twitter.ordered_accounts:
            accounts.append(
                (account.oauth_key, account.oauth_secret, account.uuid)
            )

        with open(self.data_path / 'accounts.json', 'w') as fd:
            json.dump(accounts, fd)


class TweetStore(QObject):
    def __init__(self):
        QObject.__init__(self)
        self._store = {}

    @staticmethod
    def key(data):
        return data['account'], data['type'], data['args']

    @pyqtSlot("QVariant")
    def store(self, data):
        self._store[self.key(data)] = data['tweets']

    @pyqtSlot("QVariant")
    def append(self, data, tweets):
        try:
            self._store[self.key(data)].extend(data['tweets'])
        except KeyError:
            pass

    @pyqtSlot("QVariant", result="QVariant")
    def load(self, data):
        try:
            return self._store.pop(self.key(data))
        except KeyError:
            return False



from datetime import datetime

def format_datetime(dt):
    delta = datetime.now() - dt
    if delta.total_seconds() > 60 * 60 * 24:
        return dt.strftime(u"%d.%m. %H:%M:%S")
    elif delta.seconds > 3600:
        return dt.strftime(u"%H:%M:%S")
    else:
        return u"{0}m ago".format(delta.seconds / 60)


def main():
    twitter = Twitter()
    tweet_store = TweetStore()
    app = Tweethon(sys.argv, twitter)

    declarative_view = QDeclarativeView()
    declarative_view.setViewport(QGLWidget())
    declarative_view.setResizeMode(QDeclarativeView.SizeRootObjectToView)

    root_context = declarative_view.rootContext()
    root_context.setContextProperty('twitter', twitter)
    root_context.setContextProperty('tweethon', app)
    root_context.setContextProperty('tweet_store', tweet_store)

    declarative_view.setSource(QUrl.fromLocalFile("tweethon.qml"))

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
