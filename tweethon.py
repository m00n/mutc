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


class Twitter(QObject):
    sig = pyqtSignal("QVariant")

    @pyqtSlot(result=unicode)
    def get_foo(self):
        print "get_foo_called"
        return u"abcd"


    @pyqtSlot("QVariant")
    def subscribe(self, subscription):
        print subscription


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

#@Slot(unicode, result=unicode)
def zort(foo="123"):
    print foo
    return u"foo"

def foo():
    print "guiReady"

@pyqtSlot('QVariant')
def f(args):
    print args


def main():
    app = Tweethon(sys.argv)
    twitter = Twitter()

    declarative_view = QDeclarativeView()
    declarative_view.setViewport(QGLWidget())

    root_context = declarative_view.rootContext()
    root_context.setContextProperty('twitter', twitter)
    root_context.setContextProperty('tweethon', app)

    declarative_view.setSource(QUrl.fromLocalFile("tweethon.qml"))

    root_object = declarative_view.rootObject()
    #root_object.coonect(root_object, SIGNAL('guiReady()'), )

    declarative_view.show()

    app.exec_()

if __name__ == '__main__':
    main()
    #app = App([])

    #dv = QDeclarativeView()
    #dv.setViewport(QGLWidget())
    #dv.setResizeMode(QDeclarativeView.SizeRootObjectToView)
    #rc = dv.rootContext()
    #tw = Twitter()
    #QTimer.singleShot(1000, lambda: tw.sig.emit({'a': 'b', 'c': 'd'}))
    #rc.setContextProperty('twitter', tw)
    #rc.setContextProperty('app', app)
    #dv.setSource(QUrl.fromLocalFile("tweethon.qml"))
    #ro = dv.rootObject()
    #ro.connect(ro, SIGNAL('guiReady()'), foo)
    #dv.show()

    #app.backendReady.emit()
    #app.announceAccount.emit({'avatar': 'm00n_s.png', 'screen_name': 'python', 'oauth': ''})
    #app.exec_()
