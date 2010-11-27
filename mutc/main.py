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
import json
import webbrowser
from time import strptime

import sip
sip.setapi('QString', 2)
sip.setapi('QVariant', 2)
sip.setapi('QDateTime', 2)
from PyQt4.Qt import *
from path import path

from twitter import Account, Twitter, TwitterThread
from utils import discover_proxy


if strptime("12", "%H"):
    """
    This seems to cure the AttributeError: _strptime_time bug which
    seems to be related to the use of strptime in a thread before it's there
    """
    pass


class App(QApplication):
    backendReady = pyqtSignal()

    def __init__(self, args, twitter):
        QApplication.__init__(self, args)

        self.proxy_host, self.proxy_port = discover_proxy()
        self.twitter = twitter
        self.twitter.accountCreated.connect(self.apply_proxy)

        self.data_path = path('~/.mutc').expand()

        if not self.data_path.exists():
            self.data_path.mkdir()

        self.aboutToQuit.connect(self._on_shutdown)

    def apply_proxy(self, account):
        account.proxy_host = self.proxy_host
        account.proxy_port = self.proxy_port

    def load_accounts(self):
        try:
            with open(self.data_path / 'accounts.json') as fd:
                accounts = json.load(fd)
        except IOError:
            pass
        else:
            for accout_data in accounts:
                account = Account(*accout_data)
                self.apply_proxy(account)
                self.twitter.add_account(account)

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


class ProxyNetworkAccessManagerFactory(QDeclarativeNetworkAccessManagerFactory):
    def __init__(self, proxy_host, proxy_port):
        QDeclarativeNetworkAccessManagerFactory.__init__(self)
        self.proxy_host, self.proxy_port = proxy_host, proxy_port

    def create(self, parent):
        network = QNetworkAccessManager(parent)

        if self.proxy_host and self.proxy_port:
            proxy = QNetworkProxy()
            proxy.setType(QNetworkProxy.HttpProxy)
            proxy.setHostName(self.proxy_host)
            proxy.setPort(self.proxy_port)

            network.setProxy(proxy)

        return network


def main():
    twitter = Twitter()
    app = App(sys.argv, twitter)

    declarative_view = QDeclarativeView()
    declarative_view.setViewport(QGLWidget())
    declarative_view.setResizeMode(QDeclarativeView.SizeRootObjectToView)

    factory = ProxyNetworkAccessManagerFactory(app.proxy_host, app.proxy_port)
    declarative_view.engine().setNetworkAccessManagerFactory(factory)

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
    sys.stdout = sys.stderr

    sys.exit(main())
