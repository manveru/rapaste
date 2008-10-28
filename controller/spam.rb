class SpamController < Ramaze::Controller
  map '/spam'
  helper :paginate, :formatting, :aspect
  engine :Haml
  layout '/layout'

  def list_pending
    @pastes = Paste.filter({:private => false, :approved => nil} & ({:category => 'spam'} | {:category => nil}))
    @pager  = paginate(@pastes, :limit => $rapaste[:pager])
    @count  = @pastes.count
  end

  def list_spammy
    @pastes = Paste.filter(:private => false, :spammy => true)
    @pager  = paginate(@pastes, :limit => $rapaste[:pager])
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
end
