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

from PySide.QtGui import *
from PySide.QtCore import *
from PySide.QtDeclarative import *
from PySide.QtOpenGL import *
#def qmlify(slot):
    #def wrapped(

import sys

def dict_to_qml_map(d):
    ctxmap = QDeclarativePropertyMap()

    for key, value in d.iteritems():
        ctxmap.insert(key, value)

    return ctxmap


class Twitter(QObject):
    sig = Signal("QVariant")

    @Slot(result="QVariant")
    def get_foo(self):
        print "get_foo_called"
        #return {u"bar": 2}
        #return 0
        #buf = QBuffer(self)
        #buf.setData("zort")
        #return buf
        #self.ba = ba = QByteArray("ZORT")
        return 0

#@Slot(unicode, result=unicode)
def zort(foo):
    print foo
    return u"foo"

if __name__ == '__main__':
    app = QApplication([])

    dv = QDeclarativeView()
    dv.setViewport(QGLWidget())
    dv.setResizeMode(QDeclarativeView.SizeRootObjectToView)
    rc = dv.rootContext()
    tw = Twitter()
    dv.setSource(QUrl.fromLocalFile("tweethon.qml"))
    QTimer.singleShot(1000, lambda: tw.sig.emit({'a': 'b', 'c': 'd'}))

    dv.show()

    app.exec_()
