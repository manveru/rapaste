class AccountController < Ramaze::Controller
  helper :simple_captcha, :identity, :user
  engine :Haml
  layout '/layout'

  def login
    if request[:fail] == 'session'
      flash[:bad] =
        'Failed to login, please make sure you have cookies enabled for this site'
    end

    return unless request.post?

    openid = request[:openid].to_s.strip

    if $rapaste[:users].include?(openid)
      session[:openid] = openid
      redirect Rs(:after_login)
    end

    redirect_referrer
  end

  # This method is simply to check whether we really did login and the browser
  # sends us a cookie, if we're not logged in by now it would indicate that the
  # client doesn't support cookies or has it disabled and so unable to use this
  # site.
  def after_login
    if logged_in?
      answer R(ProfileController, user.login)
    else
      redirect Rs(:login, :fail => :session)
    end
  end
end
