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
