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

from functools import wraps

from PyQt4.Qt import QThreadPool, QRunnable

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

def discover_proxy():
    try:
        proxy_str = os.environ["HTTP_PROXY"]
    except KeyError:
        return None, None
    else:
        host, port = proxy_str.split(":")
        print "proxy", proxy_str
        return host, int(port)
