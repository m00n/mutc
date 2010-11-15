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
import webbrowser

from time import sleep, strptime
from threading import Lock
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

    def __init__(self, parent, subscriptions, logger=None):
        QThread.__init__(self, parent)
        self.subscriptions = subscriptions
        self.subscriptions_lock = threading.Lock()

        self.ticks = 1
        self.tick_count = 60

        self.running = True
        self.force_check = threading.Event()

        self.logger = logger

    def run(self):
        while self.running:
            with self.subscriptions:
                for subscription in self.subscriptions:
                    if subscription.account.api:
                        try:
                            tweets = subscription.update()
                        except tweepy.TweepError as error:
                            if self.logger:
                                self.logger.exception()
                                print "Error while fetching tweets:"
                                print type(error), error
                                print error.args, error.msg

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

    def __repr__(self):
        return "<Subscription(%r, %r, %r)>" % (
            self.account.uuid[:8],
            self.subscription_type,
            self.args
        )

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


class PanelModel(QAbstractListModel):
    UUIDRole = Qt.UserRole
    TypeRole = Qt.UserRole + 1
    ArgsRole = Qt.UserRole + 2
    ScreenNameRole = Qt.UserRole + 3
    TweetModelRole = Qt.UserRole + 4

    def __init__(self, parent, subscriptions):
        QAbstractListModel.__init__(self, parent)

        self.subscriptions = subscriptions
        self.panels = []

        self.role_to_key = {
            self.UUIDRole: "uuid",
            self.TypeRole: "type",
            self.ArgsRole: "args",
            self.ScreenNameRole: "screen_name",
        }

        self.setRoleNames(self.role_to_key)

    def rowCount(self, parent=None):
        return len(self.panels)

    def addPanel(self, subscription, pos=-1):
        if pos == -1:
            pos = self.rowCount()

        self.beginInsertRows(QModelIndex(), pos, pos)


        self.panels.append(subscription)
        with self.subscriptions:
            self.subscriptions[subscription.key()] = subscription

        self.endInsertRows()

    def data(self, index, role):
        subscription = self.panels[index.row()]
        account = subscription.account

        if account.me:
            screen_name = account.me.screen_name
        else:
            screen_name = account.uuid[:4]

        return {
            self.UUIDRole: subscription.account.uuid,
            self.TypeRole: subscription.subscription_type,
            self.ArgsRole: subscription.args,
            self.ScreenNameRole: screen_name
        }[role]

    @pyqtSlot(int, int)
    def move(self, idx_from, idx_to):
        print idx_from, idx_to
        list_idx_from = idx_from
        list_idx_to = idx_to

        rows = self.rowCount()

        if idx_from < 0 or idx_to < 0 or idx_from >= rows or idx_to >= rows:
            print "idx < 0 || > n"
            return

        #if idx_from < 0:
            #idx_from = self.rowCount()
            #list_idx_from = self.rowCount() - 1
        #elif idx_from >= self.rowCount():
            #idx_from = 0
            #list_idx_from = 0

        #if idx_to < 0:
            #idx_to = self.rowCount()
            #list_idx_to = self.rowCount() - 1
        #elif idx_to >= self.rowCount():
            #idx_to = 0
            #list_idx_to = 0

        #idx_from = idx_from
        #idx_to = idx_to

        if idx_from < idx_to:
            idx_to, idx_from = idx_from, idx_to
            list_idx_to, list_idx_from = list_idx_from, list_idx_to
            print "s", idx_from, idx_to

        if self.beginMoveRows(
            QModelIndex(), idx_from, idx_from,
            QModelIndex(), idx_to,
        ):
            print self.panels

            panel = self.panels[list_idx_from]
            self.panels[list_idx_from] = self.panels[list_idx_to]
            self.panels[list_idx_to] = panel

            print self.panels

            self.endMoveRows()

    @pyqtSlot(int)
    def remove(self, idx):
        self.beginRemoveRows(QModelIndex(), idx, idx)

        subscription = self.panels.pop(idx)
        with self.subscriptions:
            self.subscriptions.pop(subscription.key())

        self.endRemoveRows()

        return subscription

    def setScreenName(self, uuid, screen_name):
        for row, subscription in enumerate(self.panels):
            if subscription.account.uuid == uuid:
                print "setScreenName"
                self.dataChanged.emit(self.index(row), self.index(row))


class LockableDict(dict):
    def __init__(self, *args, **kwds):
        dict.__init__(self, *args, **kwds)
        self._lock = Lock()

    def __enter__(self):
        self._lock.acquire()

    def __exit__(self, *args):
        self._lock.release()


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

        self.subscriptions = LockableDict()

        self.panel_model = PanelModel(
            self,
            self.subscriptions,
        )

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

    def on_account_connected(self, account):
        self.accountConnected.emit(account.simplify())
        self.panel_model.setScreenName(account.uuid, account.me.screen_name)

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

        if subscription.account.me:
            request['screen_name'] = subscription.account.me.screen_name
        else:
            request['screen_name'] = subscription.account.uuid[:4]

        self.newSubscription.emit(request)
        self.panel_model.addPanel(subscription)
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
        account.connected.connect(self.on_account_connected)

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

    def save_accounts(self):
        accounts = []
        for account in self.twitter.ordered_accounts:
            accounts.append(
                (account.oauth_key, account.oauth_secret, account.uuid)
            )

        with open(self.data_path / 'accounts.json', 'w') as fd:
            json.dump(accounts, fd)

    def load_panels(self):
        try:
            with open(self.data_path / 'panels.json') as fd:
                panels = json.load(fd)
        except IOError:
            pass
        else:
            for ptype, uuid, args in panels:
                self.twitter.subscribe({
                    "uuid": uuid,
                    "type": ptype,
                    "args": args
                })

    def save_panels(self):
        panels = []
        for subscription in self.twitter.panel_model.panels:
            panels.append(
                (subscription.subscription_type,
                 subscription.account.uuid,
                 subscription.args)
            )

        with open(self.data_path / 'panels.json', 'w') as fd:
            json.dump(panels, fd)


    def _on_shutdown(self):
        self.twitter.thread.running = False
        self.twitter.thread = False

        self.save_accounts()
        self.save_panels()

    @pyqtSlot("QVariant")
    def open_url(self, url):
        return webbrowser.open_new_tab(url)


def main():
    twitter = Twitter()
    app = App(sys.argv, twitter)

    declarative_view = QDeclarativeView()
    declarative_view.setViewport(QGLWidget())
    declarative_view.setResizeMode(QDeclarativeView.SizeRootObjectToView)

    root_context = declarative_view.rootContext()
    root_context.setContextProperty('twitter', twitter)
    root_context.setContextProperty('app', app)
    root_context.setContextProperty('tweet_panel_model', twitter.panel_model)

    declarative_view.setSource(
        QUrl.fromLocalFile(path(__file__).parent / "qml" / "main.qml")
    )

    root_object = declarative_view.rootObject()
    #root_object.coonect(root_object, SIGNAL('guiReady()'), )

    app.load_accounts()
    app.load_panels()
    twitter.start_sync()

    declarative_view.show()

    return app.exec_()

if __name__ == '__main__':
    import sys
    sys.stdout = sys.stderr

    sys.exit(main())
