class Paste < Sequel::Model
  set_schema do
    primary_key :id

    text    :text,    :null    => false
    varchar :syntax,  :null    => false
    varchar :ip,      :null    => false
    varchar :digest,  :size    => 40
    boolean :archive, :default => false
    boolean :private, :default => false
    time    :created
  end

  def text_fragment
    Highlight.new.fragment(self)
  end

  def text_full
    Highlight.new.full(self)
  end

  def syntax_description
    $rapaste[:syntaxes][syntax]
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

  create_table unless table_exists?
end
