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

from PyQt4.Qt import *

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

class QTweet(QObject):
    def __init__(self, status):
        QObject.__init__(self)
        self.status = status

    @pyqtProperty(unicode)
    def message(self):
        return self.status.text

    @pyqtProperty("QDateTime")
    def created_at(self):
        return self.status.created_at

    @pyqtProperty("QVariant")
    def author(self):
        return author_to_dict(self.status.author)


class TweetModel(QAbstractListModel):
    AuthorRole, MessageRole, CreatedRole = range(Qt.UserRole, Qt.UserRole + 3)

    def __init__(self):
        QAbstractListModel.__init__(self)

        self.tweets = []
        #self.setRoleNames(["author", "message"])
        self.setRoleNames({
            self.AuthorRole: "author",
            self.MessageRole: "message",
            self.CreatedRole: "created_at"
        })

    def oldestId(self):
        print "oldestID", self.tweets[0].created_at, self.tweets[-1].created_at
        return self.tweets[-1].id_str

    def insertTweets(self, tweets, pos):
        if pos == -1:
            pos = len(self.tweets)

        self.beginInsertRows(QModelIndex(), pos, len(tweets))
        print "self.begin"
        for i, tweet in enumerate(tweets):
            self.tweets.insert(pos + i, tweet)
            print "insert to ds"
        self.endInsertRows()
        print "self.end"

    def rowCount(self, parent):
        return len(self.tweets)

    def data(self, index, role):
        status = self.tweets[index.row()]

        if role == self.AuthorRole:
            return author_to_dict(status.author)
        elif role == self.MessageRole:
            return status.text
        elif role == self.CreatedRole:
            return status.created_at.strftime("%H:%M")


def main():
    import sys
    app = QApplication(sys.argv)

    declarative_view = QDeclarativeView()
    declarative_view.setViewport(QGLWidget())
    declarative_view.setResizeMode(QDeclarativeView.SizeRootObjectToView)

    root_context = declarative_view.rootContext()

    model = TweetModel()
    #model.insertTweets([QTweet(FakeStatus)], 0)

    root_context.setContextProperty('tweetmodel', model)
    #root_context.setContextProperty('tweethon', app)
    #root_context.setContextProperty('tweet_store', tweet_store)

    declarative_view.setSource(QUrl.fromLocalFile("testmodels.qml"))

    #root_object = declarative_view.rootObject()
    #root_object.coonect(root_object, SIGNAL('guiReady()'), )

    #app.load_accounts()

    declarative_view.show()

    return app.exec_()

if __name__ == '__main__':
    main()
