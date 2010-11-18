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
from uuid import uuid4
from functools import *
from itertools import *

import tweepy

from PyQt4.QtGui import *
from PyQt4.QtCore import *

from utils import async


CK = "owLrhjNm3qUOHA1ybLnZzA"
CS = "lycIVjOXaALggV18Cgec9mOFkDqC1hNXoFxHet5dEg"

def test():
    auth = tweepy.OAuthHandler(CK, CS)

    print auth.get_authorization_url()

    # Get access token
    auth.get_access_token(raw_input('verifier ~> '))

    print auth.access_token.key
    print auth.access_token.secret

    # Construct the API instance
    api = tweepy.API(auth)
    return api


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
        self._auth.set_access_token(self.oauth_key, self.oauth_secret)
        self.api = tweepy.API(self._auth)
        self.me = self.api.me()

        print self.me.screen_name, "connected ->", self.api.test()

        if self.api.test():
            self.connected.emit(self)
            print self.me.screen_name, "api.test passed"
        else:
            # XXX
            self.connectionFailed.emit(self)
            print self.me.screen_name, "api.test faild"

    #@pyqtSlot(result="QVariant")
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

