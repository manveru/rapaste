$rapaste = {
  # Use :uv or :coderay for highlighting
  :engine => :coderay,

  # How many pastes to show in the list view on one page
  :pager    => 12,

  # How many lines to show per paste in preview
  :fragment => 10,

  # Priority of syntaxes listed in the drop-down menu
  # Note that highlighting engines usually differ in the names, see the readme
  # for more details.
  :priority => %w[
    ruby
    plain_text plaintext
    html
    css
    javascript java_script
    yaml
    diff
  ],

  # only used by uv
  :theme    => 'iplastic',

  # title of page
  :title    => 'RaPaste',

  # list of openids that may login
  :users    => [
    'http://manveru.myopenid.com',
  ],

  # You might want to edit start.rb directly.
  :ramaze => {
    :port => 7000,
    :host => '0.0.0.0',
    :adapter => :thin
  }
}

DB = Sequel.sqlite( File.join( __DIR__, 'db/rapaste.db' ) ) #, :logger => Ramaze::Log)
