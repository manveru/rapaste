begin; require 'rubygems'; rescue LoadError; end
require 'ramaze'
require 'sequel'

$LOAD_PATH.unshift(__DIR__)

require 'env'
require 'vendor/highlight'
require 'model'
require 'controller/css'
require 'controller/paste'

class Highlight
  def default_options
    { :engine => $rapaste[:engine],
      :fragment => $rapaste[:fragment] }
  end

  mod = EXTEND[$rapaste[:engine]]
  mod.setup(__DIR__)
  $rapaste[:syntaxes] = mod.syntaxes($rapaste[:priority])
end

Ramaze.start $rapaste[:ramaze]
