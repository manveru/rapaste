Ramaze::Route[%r!^/(\d+)$!]       = '/view/%d'     # /id        = /view/id
Ramaze::Route[%r!^/(\d+)/(\w+)$!] = '/view/%d/%s'  # /id/digest = /view/id/digest

Ramaze::Route[:custom] = lambda{|path|
  case path
  when %r!^/(\d+)\.(html?|svg|mk?d)$!
    "/#$2/#$1"                              # /id.type        = /type/id
  when %r!^/(\d+)/(\w+)\.(html?|svg|mk?d)$!
    "/#$3/#$1/#$2"                          # id/digest.type  = /type/id/digest
  when %r!^/(\d+)\.(\w+)$!]
    "/plain/#$1"                            # /id.type        = /plain/id
  when %r!^/(\d+)/(\w+)\.(\w+)$!]
    "/plain/#$1/#$2"              # /id/digest.type = /plain/id/digest
  end
}

class PasteController < Ramaze::Controller
  map '/'
  helper :paginate, :formatting, :aspect
  engine :Haml
  layout :layout

  # Creating new paste
  def index
    @syntaxes = $rapaste_syntaxes

    if @fork = request[:fork]
      @paste = paste_for(@fork, digest = nil, redirect = false)
    end

    @paste ||= Paste.new
  end

  # TODO: choose a faster hashing method?
  def save
    syntax, text, private = request[:syntax, :text, :private]
    private = !!private # force to boolean for sequel

    if request.post? and text and $rapaste_syntaxes[syntax]
      paste = Paste.create(:text => text, :syntax => syntax,
        :private => private, :ip => request.ip)

      redirect paste.link(:href)
    end

    redirect_referrer
  end

  # Listing pastes

  def list
    @pastes = paste_list
    @pager = paginate(@pastes, :limit => $rapaste[:pager])
    @title = "Listing #{@pager.count} of #{@pastes.count} pastes"
  end

  def search
    return unless @needle = request['substring'] and not @needle.empty?
    @pastes = paste_list.filter(:text.like("%#{@needle}%"))
    limit = $rapaste[:pager]
    @pager = paginate(@pastes, :limit => limit)
    @title = "Listing #{@pager.count} of #{@pastes.count} results for '#{h(@needle)}'"
  end

  # Operations on single paste

  def view(id, digest = nil)
    @paste, @digest = paste_for(id, digest)
  end

  def plain(id, digest = nil)
    respond paste_for(id, digest).text, 200, 'Content-Type' => 'text/plain'
  end

  def html(id, digest = nil)
    respond paste_for(id, digest).text, 200, 'Content-Type' => 'text/html'
  end
  alias htm html

  def svg(id, digest = nil)
    respond paste_for(id, digest).text, 200, 'Content-Type' => 'image/svg+xml'
  end

  def mkd(id, digest = nil)
    require 'maruku'
    html = Maruku.new(paste_for(id, digest).text).to_html
    respond(html, 200, 'Content-Type' => 'text/html')
  end
  alias md mkd

  # TODO: the behaviour of forking a private paste isn't implemented yet,
  #       suggestions welcome
  def fork(id, digest = nil)
    redirect Rs(:fork => id, :digest => digest)
  end

  # TODO: implement this using something like session[:pastes]
  def delete(id, digest = nil)
    redirect_referrer unless request.post?
    paste = paste_for(id, digest)
  end

  # Utility methods

  def paste_list
    Paste.order(:id.desc).filter(({:archive => true, :private => false, :category => 'ham'} & ({:approved => true} | {:approved => nil})) | {:ip => request.ip})
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
