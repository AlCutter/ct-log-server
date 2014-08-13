An implementation of the Certificate Transparency HTTP API, as defined by
RFC6962.


# System Requirements

To run this application, you will require all of the gems in the Gemfile
(`bundle install` will take care of that for you), and you will also need a
local Redis instance (for work queues and caching), and a whole pile of
diskspace to store all of the certificates you're going to get.


# Development

To get your local development environment up to snuff (install all the gems
you need), run:

    bundle install --without deployment

Load up the database schema in your dev environment:

    rake load_schema

You can now run a local devserver for the API, if you like:

    rake devserver

Code lives in `lib/`; `find lib -type f` for the full list of files.
Everything should be well-commented, so you can discover what's what just by
reading each file.


## Unit Testing

To begin with, you probably want to fire up `guard` in a convenient terminal
window, to show you what you're breaking as you hack around:

    rake guard

All the specs live in `spec/`.


# Licence and copyright statement

Except as otherwise indicated, all code in this git repository is Copyright
(C) 2014 Matt Palmer, <mpalmer@hezmatt.org>.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License version 3 as published by
    the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

The full terms of the GPLv3 are provided in the file LICENCE.
