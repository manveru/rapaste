Ramaze::Route[%r!^/(\d+)$!]              = '/view/%d'     # /id             = /view/id
Ramaze::Route[%r!^/(\d+)/(\w+)$!]        = '/view/%d/%s'  # /id/digest      = /view/id/digest
Ramaze::Route[%r!^/(\d+)\.html$!]        = '/html/%d'     # /id.html        = /html/id
Ramaze::Route[%r!^/(\d+)/(\w+)\.html$!]  = '/html/%d/%s'  # /id/digest.html = /html/id/digest
Ramaze::Route[%r!^/(\d+)\.(\w+)$!]       = '/plain/%d'    # /id.type        = /plain/id
Ramaze::Route[%r!^/(\d+)/(\w+)\.(\w+)$!] = '/plain/%d/%s' # /id/digest.type = /plain/id/digest

class PasteController < Ramaze::Controller
  map '/'
  helper :paginate, :formatting, :aspect
  engine :Haml
  layout :layout

  def index
    @syntaxes = $rapaste[:syntaxes]

    if @fork = request[:fork]
      @paste = paste_for(@fork, digest = nil, redirect = false)
    end

    @paste ||= Paste.new
  end

  def list
    @pastes = paste_list
    @pager = paginate(@pastes, :limit => $rapaste[:pager])
    @total = @pastes.count
  end

  def view(id, digest = nil)
    @paste, @digest = paste_for(id, digest)
  end

  def plain(id, digest = nil)
    respond paste_for(id, digest).text, 200, 'Content-Type' => 'text/plain'
  end

  def html(id, digest = nil)
    respond paste_for(id, digest).text, 200, 'Content-Type' => 'text/html'
  end

  # TODO: choose a faster hashing method?
  def save
    syntax, text, private = request[:syntax, :text, :private]
    private = !!private # force to boolean for sequel

    if request.post? and text and $rapaste[:syntaxes][syntax]
      paste = Paste.create(
        :category => BAYES.classify(text)
        :created  => Time.now,
        :private  => private,
        :syntax   => syntax,
        :digest   => Digest::SHA1.hexdigest(text),
        :text     => text,
        :ip       => request.ip,
      )

      session[:pastes] ||= Set.new
      session[:pastes] << paste.id

      redirect paste.link(:href)
    end

    redirect_referrer
  end


  # TODO: the behaviour of forking a private paste isn't implemented yet,
  #       suggestions welcome
  def fork(id, digest = nil)
    redirect Rs(:fork => id, :digest => digest)
  end

  # TODO: implement this using the session[:pastes]
  def delete(id, digest = nil)
    redirect_referrer unless request.post?
    paste = paste_for(id, digest)
  end

  def search
    return unless @needle = request['substring'] and not @needle.empty?
    needle = "%#{@needle}%"
    @pastes = Paste.filter(:text.like(needle) & ({:archive => true, :private => false, :category => 'ham'} | {:ip => request.ip}))
    @total = @pastes.count
    @pager = paginate(@pastes, :limit => $rapaste[:pager])
  end

  def paste_list
    Paste.order(:id.desc).filter({:archive => true, :private => false, :category => 'ham'} | {:ip => request.ip})
  end

  # TODO: This could be improved.
  def paste_for(id, digest = nil, redirect_on_failure = true)
    id = id.to_i

    if digest and paste = Paste[:id => id, :digest => digest, :private => true]
      return paste
    elsif paste = Paste[:id => id, :private => false]
      return paste if paste.ip == request.ip
      return paste if paste.archive
      paste.archive = true
      paste.categorize!
      return paste
    end

    redirect("/") if redirect_on_failure
  end

  def theme
    theme = session[:theme] || $rapaste[:theme]
  end

  # FIXME: right now there is no way to set the theme in the UI
  def get_theme
    respond theme, 200, {'Content-Type' => 'text/plain'}
  end

  def set_theme(theme)
    session[:theme] = theme
    respond theme, 200, {'Content-Type' => 'text/plain'}
  end

  private

  # This method is very handy for creating a lot of pastes on the fly, just
  # comment the `private` statmenet above and access it over /create_random
  def create_random
    private = [true, false].choice
    ip = Array.new(4){ (100..255).to_a.choice }.join('.')
    file = Dir['**/*.{rb,css}'].choice
    text = File.read(file)
    syntax = {'.rb' => 'ruby', '.css' => 'css'}[File.extname(file)]

    paste = Paste.create(
      :created => Time.now,
      :digest  => Digest::SHA1.hexdigest(text),
      :ip      => ip,
      :private => private,
      :syntax  => syntax,
      :text    => text
    )

    redirect Rs(:list)
  end
end
