class Paste < Sequel::Model
  set_schema do
    primary_key :id

    text    :text,     :null    => false
    varchar :syntax,   :null    => false
    time    :created

    varchar :ip,       :null    => false
    varchar :digest,   :size    => 40
    varchar :category, :size    => 4     # last classification from bayes

    boolean :archive,  :default => false # should be publicly listed
    boolean :private,  :default => false # shouldn't be listed and needs digest for access
    boolean :approved                    # should be listed and ain't spam
  end

  validations.clear
  validates do
    presence_of :text, :syntax, :ip
    format_of :text, :with => /\A.*\S+.*\Z/m, :message => 'is empty'
    format_of :syntax, :with => /\A.*\S+.*\Z/m, :message => 'is empty'
  end

  before_create(:prepare){
    self.created  = Time.now
    self.digest   = self.hashify
    self.category = self.categorize
  }

  def text_fragment
    Highlight.new.fragment(self)
  end

  def text_full
    Highlight.new.full(self)
  end

  def syntax_description
    $rapaste_syntaxes[syntax]
  end

  include Ramaze::Helper::Link

  def link(name)
    ident = [id]
    ident << digest if private

    case name
    when :fork, :delete
      A(name.to_s.capitalize, :href => R(PasteController, name, *ident))
    when :html, :txt, :rb
      file = "#{ident * '/'}.#{name}"
      title = "#{id}.#{name}"
      A(title, :href => R(PasteController, file))
    when :href
      R(PasteController, *ident)
    end
  end

  def hashify
    Digest::SHA1.hexdigest(text)
  end

  # Interaction with Bayesian filter

  def classify
    BAYES.classify(text)
  end

  def spam!
    BAYES.train :spam, text
    self.approved = false
    categorize!
  ensure
    BAYES.store
  end

  def ham!
    BAYES.train :ham, text
    self.approved = true
    categorize!
  ensure
    BAYES.store
  end

  def categorize!
    categorize
    save
  end

  def categorize
    self.category = BAYES.classify(text).to_s
  end

  begin
    create_table
  rescue Sequel::DatabaseError => e
    if e.message !~ /table.*already exists/
      raise e
    end
  end
end
