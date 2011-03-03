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

import sys
import threading
from functools import partial, wraps
from itertools import imap
from uuid import uuid4
from time import sleep

import tweepy
from logbook import Logger
from PyQt4.QtGui import *
from PyQt4.QtCore import *

from models import PanelModel, TweetModel, DMTweetModel
from subscriptions import create_subscription
from utils import LockableDict, async, safe_api_request, tweet_to_html

CK = "owLrhjNm3qUOHA1ybLnZzA"
CS = "lycIVjOXaALggV18Cgec9mOFkDqC1hNXoFxHet5dEg"

class Account(QObject):
    authURLReady = pyqtSignal('QVariant')
    ready = pyqtSignal()
    connected = pyqtSignal(QObject)
    connectionFailed = pyqtSignal(QObject)
    authFailed = pyqtSignal(QObject)
    authSuccessful = pyqtSignal(QObject)

    def __init__(self, oauth_key=None, oauth_secret=None, uuid=None):
        QObject.__init__(self)

        self.uuid = uuid or uuid4().get_hex()
        self.oauth_key = oauth_key
        self.oauth_secret = oauth_secret

        self._auth = tweepy.OAuthHandler(CK, CS)

        self.proxy_host, self.proxy_port = None, None

        self.api = None
        self.me = None

    def __repr__(self):
        return "<Account %s>" % (
            self.me.screen_name if self.me else self.uuid[:4]
        )

    @pyqtSlot(result="QVariant")
    def get_uuid(self):
        return self.uuid

    @property
    def valid(self):
        return self.oauth_key and self.oauth_secret

    @pyqtSlot()
    @async
    def request_auth(self):
        auth_url = self._auth.get_authorization_url()
        print >>sys.stderr, "request_auth", auth_url
        self.authURLReady.emit(auth_url)

    @pyqtSlot("QVariant")
    @async
    def set_verifier(self, code):
        print >>sys.stderr, "set_verifier", code
        try:
            self._auth.get_access_token(code)
        except tweepy.TweepError as error:
            self.authFailed.emit(self)
        else:
            self.authSuccessful.emit(self)

            self.oauth_key = self._auth.access_token.key
            self.oauth_secret = self._auth.access_token.secret
            self.ready.emit()

            self.connect()

    @async
    def connect(self):
        try:
            safe_api_request(
                partial(
                    self._auth.set_access_token,
                    self.oauth_key,
                    self.oauth_secret
                )
            )
        except tweepy.TweepError as error:
            if isinstance(error.exception, httplib.HTTPException):
                if error.code == 401:
                    print "Auth failed:", error
                    import sys
                    sys.exit()

            self.connectionFailed.emit(self)

        self.api = tweepy.API(
            self._auth,
            proxy_host=self.proxy_host,
            proxy_port=self.proxy_port
        )
        self.me = safe_api_request(self.api.me)
        self.connected.emit(self)

    def simplify(self):
        print "account.simplify", self.me, bool(self.me)
        return {
            'uuid': self.uuid,
            'oauth': '{0}/{1}'.format(self.oauth_key, self.oauth_secret),
            'avatar': self.me.profile_image_url if self.me else "",
            'screen_name': self.me.screen_name if self.me else self.uuid[:4],
            'connected': self.valid and self.api,
            'active': False
        }



class Twitter(QObject):
    newTweets = pyqtSignal(object, list)
    newSubscription = pyqtSignal("QVariant")

    announceAccount = pyqtSignal("QVariant")
    accountConnected = pyqtSignal("QVariant")
    accountAuthFailed = pyqtSignal("QVariant")
    accountCreated = pyqtSignal(QObject)

    tweetRemoved = pyqtSignal("QVariant")
    tweetChanged = pyqtSignal(bool, unicode, object)

    newTweetsForModel = pyqtSignal(TweetModel, list, int)

    requestSent = pyqtSignal("QVariant", "QVariant")

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

        self.thread = TwitterThread(self, self.subscriptions, Logger("thread"))
        self.thread.newTweets.connect(self.newTweets.emit)
        self.thread.start()

    def locking(func):
        @wraps(func)
        def wrapper(self, *args, **kwds):
            try:
                func(self, *args, **kwds)
            except Exception as error:
                self.requestSent.emit(False, unicode(error))
            else:
                self.requestSent.emit(True, None)

        return wrapper

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

        if request["type"] == "direct messages":
            model_class = DMTweetModel
        else:
            model_class = TweetModel

        self.models[key] = model = model_class(self, subscription)
        self.tweetRemoved.connect(model.removeTweet)
        self.tweetChanged.connect(model.replaceTweet)

        if subscription.account.me:
            request['screen_name'] = subscription.account.me.screen_name
        else:
            request['screen_name'] = subscription.account.uuid[:4]

        self.newSubscription.emit(request)
        self.panel_model.addPanel(subscription)
        self.thread.force_check.set()

    @pyqtSlot("QVariant", "QVariant", "QVariant")
    @async
    @locking
    def tweet(self, accounts, tweet, in_reply=None):
        in_reply = in_reply if in_reply else None

        for account in imap(self.account, accounts):
            safe_api_request(
                lambda api=account.api: api.update_status(tweet, in_reply)
            )

    @pyqtSlot("QVariant", "QVariant")
    @async
    @locking
    def retweet(self, accounts, tweet_id):
        for account in imap(self.account, accounts):
            status = safe_api_request(
                lambda api=account.api: api.retweet(tweet_id),
            )
            old_status = safe_api_request(
                lambda: account.api.get_status(tweet_id)
            )

            status.retweeted = True
            status.created_at = old_status.created_at

            if hasattr(old_status, "retweeted_status"):
                # RTed a retweet
                status.other_retweet = old_status

            self.tweetChanged.emit(False, tweet_id, status)

    @pyqtSlot("QVariant", "QVariant")
    @async
    @locking
    def undo_retweet(self, accounts, tweet_id):
        for account in imap(self.account, accounts):
            status = safe_api_request(
                lambda: account.api.destroy_status(tweet_id)
            )
            self.tweetChanged.emit(True, tweet_id, status.retweeted_status)

    @pyqtSlot("QVariant", "QVariant", "QVariant")
    @async
    @locking
    def send_direct_message(self, from_uuid, to_twitter_id, text):
        account = self.account(from_uuid)
        safe_api_request(
            lambda: account.api.send_direct_message(
                user_id=to_twitter_id,
                text=text
            )
        )

    @pyqtSlot("QVariant")
    @async
    @locking
    def destroy_tweet(self, tweet_id):
        status = self.accounts.values()[0].api.get_status(tweet_id)
        author_id = status.author.id

        for account in self.accounts.values():
            if author_id == account.me.id:
                account.api.destroy_status(tweet_id)
                self.requestSent.emit(True, None)

                self.tweetRemoved.emit(tweet_id)

                break
        else:
            raise TweepError(
                "This tweet doesn't belong to any of your accounts"
            )

    @pyqtSlot("QVariant", "QVariant")
    @async
    @locking
    def destroy_direct_message(self, uuid, tweet_id):
        account = self.account(uuid)
        safe_api_request(
            lambda: account.api.destroy_direct_message(tweet_id)
        )
        self.tweetRemoved.emit(tweet_id)

    def announce_account(self, account):
        print account
        print account.simplify()
        self.announceAccount.emit(account.simplify())

    @pyqtSlot(result=QObject)
    def new_account(self):
        account = Account()
        account.ready.connect(partial(self.announce_account, account))
        account.authFailed.connect(
            lambda account: self.accountAuthFailed.emit(account.simplify())
        )
        self.add_account(account)
        self.accountCreated.emit(account)
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

    @pyqtSlot("QVariant", result="QVariant")
    def tweet_to_html(self, text):
        return tweet_to_html(text)


class TwitterThread(QThread):
    newTweets = pyqtSignal(object, object)

    def __init__(self, parent, subscriptions, logger=None):
        QThread.__init__(self, parent)
        self.subscriptions = subscriptions

        self.ticks = 1
        self.tick_count = 60

        self.running = True
        self.force_check = threading.Event()

        self.logger = logger

    def run(self):
        while self.running:
            self.check_subscriptions()
            self.stepped_sleep()

    def check_subscriptions(self):
        with self.subscriptions:
            subscriptions = self.subscriptions.values()

        self.logger.debug("Checking {0} subscriptions", len(subscriptions))

        for subscription in subscriptions:
            if subscription.account.api:
                try:
                    tweets = subscription.update()
                except tweepy.TweepError as error:
                    self.logger.exception("Error while fetching tweets")
                except Exception as exc:
                    self.logger.exception("Unexpected exception")
                else:
                    if tweets:
                        self.logger.debug("{0} new tweets for {1}/{2}",
                            len(tweets),
                            subscription.account,
                            subscription.subscription_type
                        )
                        self.newTweets.emit(subscription, tweets)

    def stepped_sleep(self):
        for x in xrange(self.tick_count):
            sleep(self.ticks)
            if self.force_check.is_set():
                self.force_check.clear()
                break


