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

from distutils.core import setup

setup(
    name='mutc',
    version='0.1.0',
    description='A twitter client using pyqt & qml',
    author='Yannick "m00n" Schaefer',
    author_email='m00n@chillaz-net.de',
    url='http://github.com/m00n/mutc',
    packages=['mutc'],
    #package_dir={'mutc': 'mutc/'},
    package_data={'mutc': [
        'qml/dummydata/*',
        'qml/*.gif',
        'qml/*.qml',
        'qml/*.js'
    ]},
    scripts=['scripts/mutc'],
)

