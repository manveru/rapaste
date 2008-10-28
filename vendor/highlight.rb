class Highlight
  # Note that the key should match the string used for require
  EXTEND = {}

  attr_accessor :paste

  def initialize(options = {})
    @options = default_options.merge(options)
    @paste = nil

    engine = @options[:engine]

    if mod = EXTEND[engine]
      require engine.to_s
      extend mod
    else
      raise(ArgumentError, "Unknown engine: %p" % engine)
    end
  end

  # forces the default_options to stay in sync
  def default_options
    {:engine => :coderay, :fragment => 10}
  end

  def fragment(paste = @paste)
    @paste = paste
    highlight paste.text.split(/[\n\r]+/)[0..10].join("\n")
  end

  def full(paste = @paste)
    @paste = paste
    highlight paste.text
  end

  module HighlightUv
    Highlight::EXTEND[:uv] = self

    DEFAULT = {
      :syntax => nil,
      :style => 'iplastic',
      :headers => false,
      :line_numbers => false,
      :output => 'xhtml',
    }

    # def Uv.parse(text, output = "xhtml", syntax_name = nil,
    #              line_numbers = false, render_style = "classic",
    #              headers = false)


    # highlight('foo', :syntax => :ruby)
    def highlight(text, options = {})
      options = translate(DEFAULT.merge(options))
      args = options.values_at(:output, :syntax, :line_numbers, :style, :headers)

      Uv.parse(text, *args)
    rescue => ex
      "<pre>#{Rack::Utils.escape(text)}</pre>"
    end

    def translate(options)
      options[:syntax] = (options[:syntax] || @paste.syntax).to_s
      options
    end

    def self.setup(dir)
      puts "Initializing UltraViolet"
      require 'uv'

      puts "Copying styles"
      Uv.copy_files "xhtml", dir/"public"

      puts "Initializing syntax parser"
      Uv.init_syntaxes

      return self
    end

    def self.syntaxes(priority = [])
      dict = Ramaze::Dictionary.new

      syntaxes = Uv.instance_variable_get('@syntaxes')
      all = syntaxes.keys
      rest = (all - priority).sort_by{|key| syntaxes[key].name }

      ((priority & all) + rest).each do |key|
        dict[key] = syntaxes[key].name
      end

      return dict
    end
  end

  module HighlightCodeRay
    Highlight::EXTEND[:coderay] = self

    DEFAULT = {
      :bold_every         => 10,
      :css                => :class,
      :hint               => false,
      :level              => :xhtml,
      :line_number_start  => 1,
      :line_numbers       => false,
      :style              => :cycnus,
      :tab_width          => 4,
      :wrap               => :span,
    }

    def highlight(text, options = {})
      options = translate(DEFAULT.merge(options))
      tokens = CodeRay.scan(text, options[:syntax])
      tokens.html(options)
    rescue => ex
      "<pre>#{Rack::Utils.escape(text)}</pre>"
    end

    def translate(options)
      options[:syntax] ||= @paste.syntax
      options
    end

    def self.setup(dir = nil)
      puts "Initializing Coderay"
      require 'coderay'
      return self
    end

    STYLE_NAME = {
      'c'           => 'C',
      'css'         => 'CSS',
      'delphi'      => 'Delphi',
      'diff'        => 'Diff',
      'html'        => 'HTML',
      'java'        => 'Java',
      'java_script' => 'JavaScript',
      'json'        => 'JSON',
      'nitro_xhtml' => 'Nitro XHTML',
      'plaintext'   => 'Plain Text',
      'rhtml'       => 'ERB',
      'ruby'        => 'Ruby',
      'scheme'      => 'Scheme',
      'sql'         => 'SQL',
      'xml'         => 'XML',
    }

    # TODO: generate automatically
    def self.syntaxes(priority = [])
      dict = Ramaze::Dictionary.new
      all = CodeRay::Scanners.list.sort
      rest = (all - priority).sort - ['debug']

      ((priority & all) + rest).each do |key|
        dict[key] = STYLE_NAME[key]
      end

      return dict
    end
  end
end
