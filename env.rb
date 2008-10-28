$rapaste = {
  :engine   => :coderay, # :uv or :coderay
  :fragment => 10, # how many lines to show per paste in preview
  :pager    => 9, # how many pastes to show in the list view on one page
  :priority => %w[ ruby plain_text plaintext html css javascript java_script yaml diff ],
  :theme    => 'iplastic', # only used by uv
  :title    => 'RaPaste', # title of page
  :admins   => { # hash of username and password for spamhunters
    'manveru' => 'letmein'
  }

  # You might want to edit start.rb directly.
  :ramaze => { :port => 7000, :host => '0.0.0.0' }
}

DB = Sequel.sqlite(__DIR__/'db/rapaste.db') #, :logger => Ramaze::Log)
