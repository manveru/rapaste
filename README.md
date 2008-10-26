# RaPaste

RaPaste is a fully featured web-pastebin, written in Ruby using the Ramaze web-framework.

## Features

* Syntax highlighting using CodeRay or Ultraviolet
* Forking pastes, creating a new one based on an existing paste
* Spam protection without javascript or captchas
* Easy configuration
* Use any database that Sequel supports.
* Show the paste with `Content-Type` of `text/html` or `text/plain`
* Private pastes with ids based on hashing the contents of the paste
* Pastes may have an optional limit in size

## Dependencies

* ramaze
* sequel
* uv or coderay

## Installation

    gem install ramaze sequel coderay # or uv
    git clone git://github.com/manveru/rapaste.git
    cd rapaste
    $EDITOR env.rb
    ruby start.rb
{:sh}

A gem will be provided when someone donates a rapaste.gemspec

## Configuration

Configure by editing the `$rapaste` hash and value of `DB` constant in `env.rb`

Settings are:

* :engine
  May be either :uv or :coderay
* :fragment
  How many lines are visible in the list and search preview
* :pager
  How many pastes are listed per page in list and search
* :priority
  Array of Strings with the names of the syntaxes that should be on top of the
  dropdown
* :theme
  Theme to use for Ultraviolet
* :title
  Title shown on every page

The settings for `DB` may be very different for you, it's file-based sqlite by
default, some possibilities are:

    DB = Sequel.sqlite('my_blog.db')
    DB = Sequel.connect('postgres://user:password@localhost/my_db')
    DB = Sequel.mysql('my_db', :user => 'user', :password => 'password', :host => 'localhost')
    DB = Sequel.ado('mydb')
{:ruby}

## Usage

You can immediately start pasting after a successful start.
Something you might want to be aware of is the spam protection mentioned above,
after pasting, the paste is initially only visible to you, it will show up on
searches and listings for you but for nobody else, this is done by filtering
the IP. After you pass the link on to someone else and another IP accesses the
paste it will be made visible for everybody.
I think the basic assumption is sane, but currently the id of pastes are too guessable.

## Todo

* Documentation
* More highlighting engines
* Caching
* Clean up `env.rb` and `start.rb` (maybe non-global configuration)
* More options and docs about how to change display of pastes
* Generate static CSS from view/css/screen.sass
* Reduce DB queries
* Use migrations?
* The behaviour of forking private pastes isn't specified yet
* Make the id of pastes less guessable, the current system can be made
  spam-able by a simple curl from another IP
