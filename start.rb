begin; require 'rubygems'; rescue LoadError; end
require 'ramaze'
require 'sequel'

$LOAD_PATH.unshift(__DIR__)

require 'env'

require 'vendor/highlight'
require 'vendor/bayes'

require 'model/paste'

require 'controller/css'
require 'controller/paste'
require 'controller/spam'
require 'controller/account'

class Highlight
  def default_options
    { :engine => $rapaste[:engine],
      :fragment => $rapaste[:fragment] }
  end

  mod = EXTEND[$rapaste[:engine]]
  mod.setup(__DIR__)
  $rapaste_syntaxes = mod.syntaxes($rapaste[:priority])
end

# The Bayes database contains information about the ham and spam rating of
# certain words.
# If you would like to reset it, just remove the db/bayes.marshal file.
BAYES = Bayes.new( File.join( __DIR__, 'db/bayes.marshal' ) )

# Initial seeding of the bayes filter, setting up categories and a couple of
# common ratings.
# The format of the files isn't that important, given that it should recognize
# any text.
# But you should separate words in some way (whitespace, commas, numbers...)
if BAYES.categories.empty?
  BAYES.train(:spam, File.read( File.join( __DIR__, 'db/spam.txt' ) ))
  BAYES.train(:ham,  File.read( File.join( __DIR__, 'db/ham.txt' ) ))
end

Ramaze.start $rapaste[:ramaze]
