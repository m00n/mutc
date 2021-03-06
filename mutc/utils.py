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

import os
import httplib
import socket

from cgi import escape
from functools import wraps
from threading import Lock
from time import sleep
from urlparse import urlparse

from PyQt4.Qt import *
from tweepy import TweepError
from logbook import Logger


class LockableDict(dict):
    def __init__(self, *args, **kwds):
        dict.__init__(self, *args, **kwds)
        self._lock = Lock()

    def __enter__(self):
        self._lock.acquire()

    def __exit__(self, *args):
        self._lock.release()


class CallEvent(QEvent):
    def __init__(self, func, *args, **kwds):
        QEvent.__init__(self, 1000)
        self.func = func
        self.args = args
        self.kwds = kwds


class CallInMainLoop(QObject):
    @pyqtSlot(QEvent)
    def event(self, event):
        if isinstance(event, CallEvent):
            event.func(*event.args, **event.kwds)
        return QObject.event(self, event)

    def __call__(self, func, *args, **kwds):
        QApplication.instance().postEvent(self, CallEvent(func, *args, **kwds))


call_in_mainloop = CallInMainLoop()


def async(func):
    """
    This decorator turns `func` on the fly into a QRunnable and enqueues
    it in the global QThreadPool
    """
    @wraps(func)
    def wrapper(*func_args, **func_kwds):
        def run(self, *args, **kwds):
            func(*func_args, **func_kwds)

        runnable = type(
            func.func_name + "/runnable",
            (QRunnable,),
            {
                'run': run,
            }
        )()
        QThreadPool.globalInstance().start(runnable)

    wrapper.sync = func
    return wrapper

def locking(func):
    @wraps(func)
    def wrapper(self, *args, **kwds):
        try:
            func(self, *args, **kwds)
        except Exception as error:
            self.requestSent.emit(False, unicode(error))
        else:
            self.requestSent.emit(True, None)

def discover_proxy():
    try:
        proxy_str = os.environ["http_proxy"]
    except KeyError:
        return None, None
    else:
        print "proxy", proxy_str
        proxy_url = urlparse(proxy_str)
        return proxy_url.hostname, proxy_url.port

def safe_api_request(func, on_success=lambda: None, short_wait=False):
    while True:
        try:
            value = func()
        except TweepError as error:
            sleep_time = None

            if isinstance(error.exception, httplib.HTTPException):
                sleep_time = {
                    420: 1800 if not short_wait else None,
                    500: 3,
                    502: 3,
                    503: 10,
                }.get(error.exception.code, 60)

            elif isinstance(error.exception, socket.error):
                sleep_time = 1
            elif "Not found" in unicode(error) or "OAuth" in unicode(error):
                raise
            else:
                sleep_time = 60

            Logger('api_request').warn(
                "Request failed: {} ({}) -> {}s sleep",
                error, error.exception, sleep_time
            )

            if sleep_time is None:
                raise

            sleep(sleep_time)
        except Exception:
            Logger('api_request').exception()
            raise
        else:
            on_success()
            return value
