# RaPaste

RaPaste is a fully featured web-pastebin, written in Ruby using the Ramaze web-framework.

## Features

* Syntax highlighting using CodeRay or Ultraviolet
* Forking pastes, creating a new one based on an existing paste
* Easy configuration
* Use any database that Sequel supports.
* Show the paste with `Content-Type` of `text/html` or `text/plain`
* Private pastes with ids based on hashing the contents of the paste
* Pastes may have an optional limit in size
* Spam protection without javascript or captchas
* Powerful bayesian filtering to support your quest against spam

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
* :admins
  This might be replaced at a later point, but right now it's a simple Hash of
  username and password for each person that wants to help you fight spam.

The settings for `DB` may be very different for you, it's file-based sqlite by
default, some possibilities are:

    DB = Sequel.sqlite('my_blog.db')
    DB = Sequel.connect('postgres://user:password@localhost/my_db')
    DB = Sequel.mysql('my_db', :user => 'user', :password => 'password', :host => 'localhost')
    DB = Sequel.ado('mydb')
{:ruby}

## Usage

You can immediately start pasting after a successful start, please tell us if
you don't find the user-interface intuitive enough or feel we're missing something.

Most likely your RaPaste will start to attract some crazy spammers, but don't
worry, we have you covered.
In order to keep them from messing up your listing and search and filling your
database we have added adaptable bayesian filtering.
The administration interface is located at `/spam`, you will be presented with
a list of unreviewed pastes and suggestions on how to handle them.

The other form of protection is rather simple, every paste is only considered
for visibility once it was accessed from another IP, so once someone pasted and
passes on the link, it will most likely be openend from another IP and so made
visible for everybody.
We thought this would be a reasonable first step to avoid massive flooding by
spammers, but doing manual filtering is still necessary sometimes.

Every time a new paste is created and viewed from another IP, a bayes rating is
generated based on the contents of the paste. If it is classified as spam it
won't show up in listings or searching despite being marked as archived until
you assert that this paste is indeed ham and add it to the filter.

Personally I think the basic implementation is sane, but currently the id of
pastes are still too guessable.

## About the Bayesian filter

I wrote the filter after reading articles from Paul Graham and trying the
related ruby library from Lucas Carlson called `classifier`.
Classifier proved to be a bothersome experience, and caused me some problems
and issuing warnings on startup.
But I took the core algorithm, tuned it a bit and for now the filter resides in
`vendor/bayes.rb`.
It's pure Ruby, reasonably fast and accurate.
Some design decisions were to limit it to words longer than 4 characters (apart
from a few exceptions), smaller words tend to skew the results and are often
not meaningful enough.
Unknown words have minimal impact on the result.

Further reading on bayesian filtering:

* http://www.paulgraham.com/spam.html
* http://www.process.com/precisemail/bayesian_filtering.htm
* http://en.wikipedia.org/wiki/Bayesian_filtering

### Finetuning Bayes

After your first startup you will have a new file at `db/bayes.marshal`, which
contains the marshalled contents of the @categories hash from the `Bayes`
instance.
It is seeded with some words from `db/spam.txt` and `db/ham.txt` initially, and
will grow when you use the `/spam` interface.
In case you want to correct something or change the scoring you can load it in
irb:

    bayes = Marshal.load(File.read('db/bayes.marshal'))

To write it back you simple do:

    File.open('db/bayes.marshal', 'w+'){|b| b.write(Marshal.dump(bayes)) }

So let's say you have collected some textfiles with spam and ham and would like
to train the filter with it, but without pasting:

    require 'vendor/bayes'

    bayes = Bayes.new('bayes.marshal')

    spam = File.read('stuff/spam.txt')
    ham = File.read('stuff/ham.txt')

    bayes.train :spam, spam
    bayes.train :ham, ham

    bayes.store

The final `bayes.store` will reflect the changes into `bayes.marshal` so when
you issue `Bayes.new('bayes.marshal')` next time it will automatically load
your filter.

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
* Modification of the bayes filter itself, atm the easiest way is via irb
