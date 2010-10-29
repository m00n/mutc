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


from PyQt4.Qt import *

import sys


def pick(dictionary, *keys):
    return dict((key, getattr(dictionary, key)) for key in keys)

def status_to_dict(status):
    is_rt = hasattr(status, "retweeted_status")
    retweeted_status = getattr(status, "retweeted_status", None)

    return {
        "author": author_to_dict(status.author),
        "text": status.text[3:] if is_rt else status.text,
        "created_at": status.created_at,
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

        self.ticks = 20
        self.tick_count = 3

        self.running = True
        self.force_check = threading.Event()

    def run(self):
        while self.running:
            for subscription in self.subscriptions:
                tweets = map(status_to_dict, subscription.update())
                self.newTweets.emit({
                    "account": account.uuid,
                    "type": subscription.subscription_type
                    "args": subscription.args
                    "tweets": tweets
                })

            for x in xrange(self.tick_count):
                sleep(self.ticks)
                if self.force_check.is_set():
                    self.force_check.unset()
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

        if not self.last_tweet_id:
            cursor_args["since_id"] = self.last_tweet_id

        cursor.update(self.get_stream_args())

        cursor = tweepy.Cursor(
            self.get_stream(),
            **cursor_args
        )

        for status in cursor.items():
            tweets.append(status)

        self.last_tweet_id = status.id

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
        "mentions": Mentions
        "search": Search
    }[name](account, args)


class Twitter(QObject):
    sig = pyqtSignal("QVariant")
    newTweets = pyqtSignal("QVariant")

    def __init__(self):
        self.accounts = {}
        self.subscriptions = set()

        self.thread = TwitterThread(self)
        self.thread.newTweets.connect(self.newTweets.emit)
        self.thread.start()

    @pyqtSlot("QVariant")
    def subscribe(self, subscription):
        print subscription
        self.subscriptions.add(
            create_subscription(
                subscription["type"],
                self.accounts[subscription["account"]],
                subscription.get("args", ())
            )
        )

    @pyqtSlot("QVariant")
    def tweet(self, tweet):
        """
        {
            text:
            accounts: []
        }
        """
        pass


class Tweethon(QApplication):
    backendReady = pyqtSignal()

    announceAccount = pyqtSignal('QVariant')

    def __init__(self, args):
        QApplication.__init__(self, args)

    def start_sync(self):
        """
        Emit accounts & saved options to gui
        """
        for account in self.accounts:
            self.announceAccount(account.to_builtins())


    # account methods
    """
    QML                           Python
    account = app.account_new()
    account.verifierNeeded.connect({ show_url; })
    account.connected.connect({  })
    account.get_auth_url()
    account.set_verifier(inputfu.text)
    """
    def account_new(self):
        account = Account()
        account.ready.connect(announceAccount.emit)

        self.accounts.append(account)
        #account.connected.connect(self.accounts.append)

        return account


def main():
    app = Tweethon(sys.argv)
    twitter = Twitter()

    declarative_view = QDeclarativeView()
    declarative_view.setViewport(QGLWidget())
    declarative_view.setResizeMode(QDeclarativeView.SizeRootObjectToView)

    root_context = declarative_view.rootContext()
    root_context.setContextProperty('twitter', twitter)
    root_context.setContextProperty('tweethon', app)

    declarative_view.setSource(QUrl.fromLocalFile("tweethon.qml"))

    root_object = declarative_view.rootObject()
    #root_object.coonect(root_object, SIGNAL('guiReady()'), )

    declarative_view.show()

    return app.exec_()

if __name__ == '__main__':
    sys.exit(main())
