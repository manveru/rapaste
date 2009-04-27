class AccountController < Ramaze::Controller
  helper :simple_captcha, :identity, :user
  engine :Haml
  layout 'layout'
  map_layouts '/'

  def login
    if request[:fail] == 'session'
      flash[:bad] =
        'Failed to login, please make sure you have cookies enabled for this site'
    end

    return unless request.post?
    @oid = session[:openid_identity]
    @url = request[:url] || @oid

    if @oid
      openid_finalize
    elsif request.post?
      openid_begin
    else
      flash[:bad] = flash[:error] || "Bleep"
    end
  end

  # This method is simply to check whether we really did login and the browser
  # sends us a cookie, if we're not logged in by now it would indicate that the
  # client doesn't support cookies or has it disabled and so unable to use this
  # site.
  def after_login
    if logged_in?
      answer SpamController.r(:list_pending)
    else
      redirect r(:login, :fail => :session)
    end
  end

  private

  def openid_finalize
    if $rapaste[:users].include?(@oid)
      session[:user] = @oid
      flash[:good] = flash[:success]
      redirect SpamController.r(:list_pending)
    else
      flash[:bad] = "None of our users belongs to this OpenID"
    end
  end
end
