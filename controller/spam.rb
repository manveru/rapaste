class SpamController < Ramaze::Controller
  map '/spam'
  helper :paginate, :formatting, :aspect
  engine :Haml
  layout '/layout'

  before_all do
    redirect_referrer unless $rapaste[:users].include?(session[:openid_identity])
  end

  def list_pending
    @pastes = Paste.filter({:private => false, :approved => nil} & ({:category => 'spam'} | {:category => nil}))
    @pager  = paginate(@pastes, :limit => ($rapaste[:pager] * 3))
    @count  = @pastes.count
  end

  def mark
    return unless request.post?

    request.params.each do |id, category|
      if paste = Paste[id]
        if category == 'ham'
          paste.ham!
        elsif category == 'spam'
          paste.spam!
        end
      end
    end

    session[:undo] ||= []
    session[:undo] << request.params
    session[:undo].shift until session[:undo].size < 10 # keep it reasonable

    flash[:good] = "Categorized this page, #{A('undo?', :href => Rs(:undo))}"

    redirect_referrer
  end

  def undo
    if last = session[:undo].pop
      Paste.filter(:id => last.keys.map{|k| k.to_i }).each do |paste|
        paste.category = nil
        paste.approved = nil
        paste.save
      end

      flash[:good] = "Undo successful, want to #{A('undo further?', :href => Rs(:undo))}"
    else
      flash[:bad] = "Nothing to undo"
    end

    redirect_referrer
  end

  def search
    query = request[:q]

    @pastes = Paste.filter({:private => false, :approved => nil} & ({:category => 'spam'} | {:category => nil}) & :text.like("%#{query}%"))
    @pager  = paginate(@pastes, :limit => ($rapaste[:pager] * 3))
    @count  = @pastes.count
  end

  def list_spammy
    query = request[:q]

    suspect = Paste.filter({:private => false, :approved => nil} & {:category => nil})
    spammy = []
    suspect.each{|paste| paste.categorize! }

    @pastes = Paste.filter({:private => false, :approved => nil} & ({:category => 'spam'}))
    @pager  = paginate(@pastes, :limit => ($rapaste[:pager] * 3))
    @count  = @pastes.count
  end
end
