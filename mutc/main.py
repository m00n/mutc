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
import shutil
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

    def __init__(self, args):
        QApplication.__init__(self, args)

        self.data_path = self.setup_data_path()
        self.load_config()

        self.twitter = Twitter(self.config)
        self.load_accounts()
        self.load_panels()

        self.twitter.accountCreated.connect(self.apply_proxy)

        self.aboutToQuit.connect(self._on_shutdown)

    def setup_data_path(self):
        data_path = path('~/.mutc').expand()
        if not data_path.exists():
            data_path.mkdir()
            config_filename = path(__file__).parent / "config.default.json"
            shutil.copy(config_filename, data_path / "config.json")

        return data_path

    def apply_proxy(self, account):
        account.proxy_host = self.proxy_host
        account.proxy_port = self.proxy_port

    def load_config(self):
        with open(self.data_path / 'config.json') as fd:
            self.config = json.load(fd)

        proxy = self.config["proxy"]

        if proxy["host"] and proxy["port"]:
            self.proxy_host = proxy["host"]
            self.proxy_port = proxy["port"]
        else:
            self.proxy_host, self.proxy_port = discover_proxy()

    def save_config(self):
        with open(self.data_path / 'config.json', 'w') as fd:
            json.dump(self.config, fd)

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
        self.save_config()

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


class TrayIcon(QSystemTrayIcon):
    TRAY_HEIGHT = 22

    def __init__(self, twitter, main_window):
        QSystemTrayIcon.__init__(self)

        twitter.newTweets.connect(
            lambda subscription, tweets: self.on_new_tweets(tweets)
        )

        self.main_window = main_window

        self.app_icon = QPixmap(path(__file__).dirname() / "tray_icon.png")
        self.unread_tweet_count = 0

        self.activated.connect(self.on_activated)

    @pyqtProperty(int)
    def unread_tweet_count(self):
        return self._unread_tweet_count

    @unread_tweet_count.setter
    def unread_tweet_count(self, value):
        self._unread_tweet_count = value
        if value == 0:
            self.setIcon(QIcon(self.app_icon))
            self.setToolTip("mutc")
        else:
            self.setToolTip("mutc - {0} unread tweets".format(value))
            img = self.make_icon(self.unread_tweet_count)
            self.setIcon(QIcon(QPixmap(img)))

    def on_new_tweets(self, tweets):
        if not self.main_window.isVisible():
            self.unread_tweet_count += len(tweets)

    def on_activated(self, reason):
        if reason == self.Trigger:
            self.unread_tweet_count = 0

            if not self.main_window.isVisible():
                self.main_window.showAndRestoreGeometry()
            else:
                self.main_window.hideAndStoreGeometry()

    def make_icon(self, tweet_count):
        if tweet_count < 100:
            text = unicode(tweet_count)
        elif tweet_count >= 1000:
            text = u"M"
        elif tweet_count >= 500:
            text = u"D"
        elif tweet_count >= 100:
            text = u"C"

        font = QFont()

        img = QImage(
            self.TRAY_HEIGHT,
            self.TRAY_HEIGHT,
            QImage.Format_ARGB32
        )
        img.fill(0)
        painter = QPainter(img)
        painter.fillRect(img.rect(), QColor(0, 0, 0, 0))
        painter.drawPixmap(0, 0, self.app_icon)

        font.setBold(True)
        font.setPointSize(11)
        self._draw_text_centered(painter, font, text)
        painter.end()
        return img

    def _draw_text_centered(self, painter, font, text):
        text_width = QFontMetrics(font).boundingRect(text).width()

        painter.setFont(font)
        painter.drawText(
            (self.TRAY_HEIGHT // 2) - (text_width // 2),
            self.TRAY_HEIGHT - (font.pointSize() // 2) - 1,
            text
        )


class Config(QObject):
    conversions = {
        "limits.buffer": int,
        "limits.clients": int,
        "proxy.port": int
    }

    def __init__(self, parent, config):
        QObject.__init__(self, parent)
        self.config = config

    @pyqtSlot("QVariant", "QVariant")
    def set(self, key, value):
        parts = key.split(".")
        dict_= self.config
        for part in parts[:-1]:
            dict_ = dict_[part]
        dict_[parts[-1]] = self.conversions.get(
            key, lambda x: x
        )(value)

    @pyqtSlot("QVariant", result="QVariant")
    def get(self, key):
        dict_ = self.config
        for part in key.split("."):
            dict_ = dict_[part]

        return dict_


class MainWindow(QDeclarativeView):
    def __init__(self, app):
        QDeclarativeView.__init__(self)

        self.setViewport(QGLWidget())
        self.setResizeMode(QDeclarativeView.SizeRootObjectToView)

        factory = self.factory = ProxyNetworkAccessManagerFactory(
            app.proxy_host,
            app.proxy_port
        )
        self.engine().setNetworkAccessManagerFactory(factory)

        root_context = self.rootContext()
        root_context.setContextProperty('twitter', app.twitter)
        root_context.setContextProperty('app', app)
        root_context.setContextProperty(
            'tweet_panel_model', app.twitter.panel_model
        )
        root_context.setContextProperty('config', Config(self, app.config))

        self.setSource(
            QUrl.fromLocalFile(path(__file__).parent / "qml" / "main.qml")
        )

        self.tray_icon = TrayIcon(app.twitter, self)
        self.tray_icon.show()

        self._last_geometry = None

    def changeEvent(self, event):
        if isinstance(event, QWindowStateChangeEvent):
            print event, self.isMinimized(), self.geometry()
            if self.isMinimized():
                self.hideAndStoreGeometry()

        QDeclarativeView.changeEvent(self, event)

    def hideAndStoreGeometry(self):
        self._last_geometry = self.geometry()
        self.hide()

    def showAndRestoreGeometry(self):
        if self._last_geometry:
            self.setGeometry(self._last_geometry)

        self.showNormal()


def main():
    app = App(sys.argv)

    main_window = MainWindow(app)
    main_window.show()

    app.twitter.start_sync()

    return app.exec_()

if __name__ == '__main__':
    import socket
    # Set timeout to 45s, otherwise the twitter thread will hang forever
    socket.setdefaulttimeout(45)

    sys.stdout = sys.stderr

    sys.exit(main())
