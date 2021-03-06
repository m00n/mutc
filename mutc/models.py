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

from cgi import escape
from datetime import datetime

import tweepy
from path import path
from PyQt4.Qt import *

from utils import async


def format_datetime(date, diff=[]):
    if not diff:
        diff.append(datetime.now() - datetime.utcnow())
    date = date + diff[0]

    midnight = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    if date >= midnight:
        # tweet from today
        return date.strftime(u"%H:%M:%S")
    else:
        return date.strftime(u"%d.%m. %H:%M")

def pick(dictionary, *keys):
    return dict((key, getattr(dictionary, key)) for key in keys)

def author_to_dict(user):
    return pick(
        user,
        "screen_name",
        "name",
        "description",
        "profile_image_url",
        "id_str",
    )

class AccountModel(QAbstractListModel):
    ServiceRole = Qt.UserRole
    NameRole = Qt.UserRole + 1
    UUIDRole = Qt.UserRole + 2
    StateRole = Qt.UserRole + 3
    AvatarRole = Qt.UserRole + 4
    SelectedRole = Qt.UserRole + 5
    ObjectRole = Qt.UserRole + 6
    ServiceIdRole = Qt.UserRole + 7

    DisconnectedState = 0
    ConnectedState = 1

    def __init__(self, parent):
        QAbstractListModel.__init__(self, parent)

        self.setRoleNames({
            self.ServiceRole: "service",
            self.NameRole: "screen_name",
            self.UUIDRole: "uuid",
            self.StateRole: "state",
            self.AvatarRole: "avatar",
            self.SelectedRole: "is_selected",
            self.ObjectRole: "account_obj"
        })

        self.accounts = []
        self.selected = set()

    def _on_connected(self, account):
        model_index = self.index(self.accounts.index(account))
        self.dataChanged.emit(model_index, model_index)

    @pyqtSlot(QObject)
    def addAccount(self, account):
        account.connected.connect(self._on_connected)
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())
        self.accounts.append(account)
        self.endInsertRows()

    #def removeAccount(self, account):
        #self.accounts.remove(account)

    @pyqtSlot(int)
    def select(self, index):
        model_index = self.index(index)
        self.selected.add(self.accounts[index])
        self.dataChanged.emit(model_index, model_index)

    @pyqtSlot(int)
    def deselect(self, index):
        model_index = self.index(index)
        self.selected.remove(self.accounts[index])
        self.dataChanged.emit(model_index, model_index)

    @pyqtSlot(result="QVariant")
    def getActiveAccounts(self):
        return self.selected

    def rowCount(self, _parent=None):
        return len(self.accounts)

    def data(self, index, role):
        account = self.accounts[index.row()]

        try:
            return {
                self.UUIDRole: account.uuid,
                self.StateRole: bool(account.me),
                self.SelectedRole: account in self.selected,
                self.ObjectRole: account
            }[role]
        except KeyError:
            if account.me:
                return {
                    self.ServiceRole: account.service,
                    self.NameRole: account.me.screen_name,
                    self.AvatarRole: account.me.profile_image_url,
                    self.ServiceIdRole: account.me.id_str,
                }[role]
            else:
                return ""


class TweetModel(QAbstractListModel):
    AuthorRole = Qt.UserRole
    MessageRole = Qt.UserRole + 1
    CreatedRole =  Qt.UserRole + 2
    IsRetweetRole = Qt.UserRole + 3
    RetweetByRole = Qt.UserRole + 4
    IdRole = Qt.UserRole + 5
    MyRetweetRole = Qt.UserRole + 6
    InReplyRole = Qt.UserRole + 7
    InReplyToIdRole = Qt.UserRole + 8
    MyFavoritedRole = Qt.UserRole + 9
    MyEntitiesRole = Qt.UserRole + 10

    busyStateChanged = pyqtSignal(bool)
    countChanged = pyqtSignal(int)

    def __init__(self, parent, subscription):
        QAbstractListModel.__init__(self, parent)

        self._busy = False

        self.subscription = subscription
        self.tweets = []

        subscription.newTweetsReceived.connect(
            lambda _, tweets: self.insertTweets(tweets, 0)
        )
        subscription.oldTweetsReceived.connect(
            self._on_old_tweets_recv
        )

        self.setRoleNames({
            self.AuthorRole: "author",
            self.MessageRole: "message",
            self.CreatedRole: "created_at",
            self.IsRetweetRole: "is_retweet",
            self.RetweetByRole: "retweet_by",
            self.IdRole: "tweet_id",
            self.MyRetweetRole: "my_retweet",
            self.InReplyRole: "in_reply",
            self.InReplyToIdRole: "in_reply_id",
            self.MyFavoritedRole: "my_favorite",
            self.MyEntitiesRole: "entities",
        })

    @pyqtProperty(unicode, constant=True)
    def type(self):
        return "default"

    @pyqtProperty("QVariant")
    def account(self):
        return self.subscription.account

    def _on_old_tweets_recv(self, subscription, tweets):
        self.busy = False
        #index = self.index(self.rowCount() - 1)
        #self.dataChanged.emit(index, index)
        self.insertTweets(tweets, -1)

    def is_busy(self):
        return self._busy

    def set_busy(self, value):
        self._busy = value
        self.busyStateChanged.emit(value)

    busy = pyqtProperty(bool, is_busy, set_busy, notify=busyStateChanged)

    def index_for_id(self, id_str):
        for index, status in enumerate(self.tweets):
            if status.id_str == id_str:
                return index

    def oldestId(self):
        return self.tweets[-1].id

    def insertTweets(self, tweets, pos):
        """
        inserts one or more tweets at pos
        if pos is -1 tweets are appended
        """
        if pos == -1:
            pos = len(self.tweets)

        self.beginInsertRows(QModelIndex(), pos, pos + len(tweets) - 1)
        for i, tweet in enumerate(tweets):
            self.tweets.insert(pos + i, tweet)
        self.endInsertRows()
        self.countChanged.emit(len(self.tweets))

    def removeTweet(self, id_str):
        """
        removes a single tweet identified by "id_str"
        """
        index = self.index_for_id(id_str)

        if index is None:
            # We are the wrong model, just return
            return

        self.beginRemoveRows(QModelIndex(), index, index)
        self.tweets.pop(index)
        self.endRemoveRows()

        self.countChanged.emit(len(self.tweets))

    def replaceTweet(self, restore, id_str, new_status):
        index = self.index_for_id(id_str)

        if index is None:
            return

        old_tweet = self.tweets[index]

        # Only change something if this model is meant
        if id(old_tweet._api) == id(new_status._api):
            if hasattr(old_tweet, "other_retweet") and restore:
                # This was retweeted by someone into my timeline
                new_status = old_tweet.other_retweet

            self.tweets[index] = new_status
            self.dataChanged.emit(self.index(index), self.index(index))

    @pyqtSlot(result="QVariant")
    def rowCount(self, parent=None):
        return len(self.tweets)

    count = pyqtProperty(int, rowCount, notify=countChanged)

    def data(self, index, role):
        status = self.tweets[index.row()]

        if role == self.IdRole:
            return status.id_str

        # Locke: note to myself: this seems to be ugly...
        if isinstance(status, tweepy.SearchResult):
            return self.data_search(status, role)
        elif hasattr(status, "retweeted_status"):
            return self.data_retweet(status, role)
        else:
            return self.data_default(status, role)

    def data_retweet(self, status, role):
        if role == self.AuthorRole:
            return author_to_dict(status.retweeted_status.author)
        elif role == self.MessageRole:
            return status.retweeted_status.text
        elif role == self.CreatedRole:
            return format_datetime(status.created_at)
        elif role == self.IsRetweetRole:
            return True
        elif role == self.RetweetByRole:
            return author_to_dict(status.author)
        elif role == self.MyRetweetRole:
            return status.retweeted
        elif role == self.InReplyRole:
            return status.in_reply_to_screen_name
        elif role == self.InReplyToIdRole:
            return status.in_reply_to_status_id_str
        elif role == self.MyFavoritedRole:
            return status.favorited
        elif role == self.MyEntitiesRole:
            return status.entities

    def data_default(self, status, role):
        if role == self.AuthorRole:
            return author_to_dict(status.author)
        elif role == self.MessageRole:
            return status.text
        elif role == self.CreatedRole:
            return format_datetime(status.created_at)
        elif role == self.IsRetweetRole:
            return False
        elif role == self.RetweetByRole:
            return {
                "screen_name": "",
                "profile_image_url": "",
            }
        elif role == self.MyRetweetRole:
            return False
        elif role == self.InReplyRole:
            return status.in_reply_to_screen_name
        elif role == self.InReplyToIdRole:
            return status.in_reply_to_status_id_str
        elif role == self.MyFavoritedRole:
            return status.favorited
        elif role == self.MyEntitiesRole:
            return status.entities

    def data_search(self, result, role):
        if role == self.AuthorRole:
            return {
                "screen_name": result.from_user,
                "profile_image_url": result.profile_image_url
            }
        elif role == self.MessageRole:
            return result.text
        elif role == self.CreatedRole:
            return format_datetime(result.created_at)
        elif role == self.IsRetweetRole:
            return False
        elif role == self.RetweetByRole:
            return {
                "screen_name": "",
                "profile_image_url": "",
            }
        elif role == self.RetweetByRole:
            return False
        elif role == self.MyRetweetRole:
            return False
        elif role == self.InReplyRole:
            return ""
        elif role == self.InReplyToIdRole:
            return ""
        elif role == self.MyFavoritedRole:
            return False
        elif role == self.MyEntitiesRole:
            return []

    @pyqtSlot()
    def needTweets(self):
        self.busy = True
        async(self.subscription.tweets_before)(self.oldestId())

    @pyqtSlot("QVariant", result="QVariant")
    def get(self, index):
        data = {}
        model_index = self.index(index)
        for role, name in self.roleNames().iteritems():
            data[unicode(name)] = self.data(model_index, role)

        return data


class DMTweetModel(TweetModel):
    @pyqtProperty(unicode, constant=True)
    def type(self):
        return "direct messages"

    def data(self, index, role):
        dm = self.tweets[index.row()]

        if role == self.AuthorRole:
            return author_to_dict(dm.sender)
        elif role == self.MessageRole:
            return dm.text
        elif role == self.CreatedRole:
            return format_datetime(dm.created_at)
        elif role == self.IsRetweetRole:
            return False
        elif role == self.RetweetByRole:
            return None
        elif role == self.InReplyRole:
            return author_to_dict(dm.recipient)
        elif role == self.IdRole:
            return dm.id_str
        elif role == self.MyRetweetRole:
            return False
        elif role == self.MyFavoritedRole:
            return False
        elif role == self.MyEntitiesRole:
            return []


class PanelModel(QAbstractListModel):
    UUIDRole = Qt.UserRole
    TypeRole = Qt.UserRole + 1
    ArgsRole = Qt.UserRole + 2
    ScreenNameRole = Qt.UserRole + 3
    TweetModelRole = Qt.UserRole + 4
    AccountRole = Qt.UserRole + 5

    countChanged = pyqtSignal(int, int)

    def __init__(self, parent, subscriptions):
        QAbstractListModel.__init__(self, parent)

        self.subscriptions = subscriptions
        self.panels = []

        self.role_to_key = {
            self.UUIDRole: "uuid",
            self.TypeRole: "type",
            self.ArgsRole: "args",
            self.ScreenNameRole: "screen_name",
            self.TweetModelRole: "tweet_model",
            self.AccountRole: "account_obj"
        }

        self.setRoleNames(self.role_to_key)

    @pyqtSlot(result="QVariant")
    def rowCount(self, parent=None):
        return len(self.panels)

    count = pyqtProperty(int, rowCount, notify=countChanged)

    def addPanel(self, subscription, pos=-1):
        if pos == -1:
            pos = self.rowCount()

        self.beginInsertRows(QModelIndex(), pos, pos)

        with self.subscriptions:
            self.subscriptions[subscription.key()] = subscription

        if subscription.subscription_type == "direct messages":
            model_class = DMTweetModel
        else:
            model_class = TweetModel

        model = model_class(self, subscription)
        self.panels.append((subscription, model))

        self.endInsertRows()
        self.countChanged.emit(self.count, self.count - 1)

        return model

    def data(self, index, role):
        subscription, model = self.panels[index.row()]
        account = subscription.account

        if account.me:
            screen_name = account.me.screen_name
        else:
            screen_name = account.uuid[:4]

        return {
            self.UUIDRole: subscription.account.uuid,
            self.TypeRole: subscription.subscription_type,
            self.ArgsRole: subscription.args,
            self.ScreenNameRole: screen_name,
            self.TweetModelRole: model,
            self.AccountRole: subscription.account
        }[role]

    @pyqtSlot(int, int)
    def move(self, idx_from, idx_to):
        print idx_from, idx_to
        list_idx_from = idx_from
        list_idx_to = idx_to

        rows = self.rowCount()

        if idx_from < 0 or idx_to < 0 or idx_from >= rows or idx_to >= rows:
            return

        if idx_from < idx_to:
            idx_to, idx_from = idx_from, idx_to
            list_idx_to, list_idx_from = list_idx_from, list_idx_to

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

        subscription, model = self.panels.pop(idx)
        with self.subscriptions:
            self.subscriptions.pop(subscription.key())

        self.endRemoveRows()
        self.countChanged.emit(self.count, self.count + 1)

        return subscription

    def setScreenName(self, uuid, screen_name):
        for row, (subscription, model) in enumerate(self.panels):
            if subscription.account.uuid == uuid:
                self.dataChanged.emit(self.index(row), self.index(row))
