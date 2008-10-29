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
      'plain_text'  => 'Plain Text',
      'rhtml'       => 'ERB',
      'ruby'        => 'Ruby',
      'scheme'      => 'Scheme',
      'sql'         => 'SQL',
      'xml'         => 'XML',
    }

    def self.setup(dir = nil)
      puts "Initializing Coderay"
      require 'coderay'

      # commonly used, but UV and CodeRay have different names for it
      CodeRay::Scanners.map :plain_text => :plaintext
      return self
    end

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

  # This is a dump of:
  #
  #   require 'uv'
  #   Uv.init_syntaxes
  #   syntaxes = Uv.instance_variable_get('@syntaxes')
  #   hash = Hash[*syntaxes.map{|k,v| [k, v.name] }.flatten]
  #   puts hash.sort_by{|k,v| k }.map{|k,v| "%-34p => %-p," % [k, v] }
  #
  # We put this here to be able to display the correct name of a syntax in case
  # an engine is used that doesn't support all.

  SYNTAX_NAME = {
    "actionscript"                     => "ActionScript",
    "active4d"                         => "Active4D",
    "active4d_html"                    => "HTML (Active4D)",
    "active4d_ini"                     => "Active4D Config",
    "active4d_library"                 => "Active4D Library",
    "ada"                              => "Ada",
    "antlr"                            => "ANTLR",
    "apache"                           => "Apache",
    "applescript"                      => "AppleScript",
    "asp"                              => "ASP",
    "asp_vb.net"                       => "ASP vb.NET",
    "bibtex"                           => "BibTeX",
    "blog_html"                        => "Blog \342\200\224 HTML",
    "blog_markdown"                    => "Blog \342\200\224 Markdown",
    "blog_text"                        => "Blog \342\200\224 Text",
    "blog_textile"                     => "Blog \342\200\224 Textile",
    "build"                            => "NAnt Build File",
    "bulletin_board"                   => "Bulletin Board",
    "c"                                => "C",
    "c++"                              => "C++",
    "cake"                             => "Cake",
    "camlp4"                           => "camlp4",
    "cm"                               => "CM",
    "coldfusion"                       => "ColdFusion",
    "context_free"                     => "Context Free",
    "cs"                               => "C#",
    "css"                              => "CSS",
    "css_experimental"                 => "CSS v3 beta",
    "csv"                              => "CSV",
    "d"                                => "D",
    "diff"                             => "Diff",
    "dokuwiki"                         => "DokuWiki",
    "dot"                              => "Graphviz (DOT)",
    "doxygen"                          => "Doxygen",
    "dylan"                            => "Dylan",
    "eiffel"                           => "Eiffel",
    "erlang"                           => "Erlang",
    "f-script"                         => "F-Script",
    "fortran"                          => "Fortran",
    "fxscript"                         => "FXScript",
    "greasemonkey"                     => "Greasemonkey",
    "gri"                              => "Gri",
    "groovy"                           => "Groovy",
    "gtd"                              => "GTD",
    "gtdalt"                           => "GTDalt",
    "haml"                             => "Haml",
    "haskell"                          => "Haskell",
    "html"                             => "HTML",
    "html-asp"                         => "HTML (ASP)",
    "html_django"                      => "HTML (Django)",
    "html_for_asp.net"                 => "HTML (ASP.net)",
    "html_mason"                       => "HTML (Mason)",
    "html_rails"                       => "HTML (Rails)",
    "html_tcl"                         => "HTML (Tcl)",
    "icalendar"                        => "iCalendar",
    "inform"                           => "Inform",
    "ini"                              => "Ini",
    "installer_distribution_script"    => "Installer Distribution Script",
    "io"                               => "Io",
    "java"                             => "Java",
    "javaproperties"                   => "Java Properties",
    "javascript"                       => "JavaScript",
    "javascript_+_prototype"           => "Prototype & Script.aculo.us (JavaScript)",
    "javascript_+_prototype_bracketed" => "Prototype & Script.aculo.us (JavaScript) Bracketed",
    "jquery_javascript"                => "jQuery (JavaScript)",
    "json"                             => "JSON",
    "languagedefinition"               => "Language Grammar",
    "latex"                            => "LaTeX",
    "latex_beamer"                     => "LaTeX Beamer",
    "latex_log"                        => "LaTeX Log",
    "latex_memoir"                     => "LaTeX Memoir",
    "lexflex"                          => "Lex/Flex",
    "lighttpd"                         => "Lighttpd",
    "lilypond"                         => "Lilypond",
    "lisp"                             => "Lisp",
    "literate_haskell"                 => "Literate Haskell",
    "logo"                             => "Logo",
    "logtalk"                          => "Logtalk",
    "lua"                              => "Lua",
    "m"                                => "MATLAB",
    "macports_portfile"                => "MacPorts Portfile",
    "mail"                             => "Mail",
    "makefile"                         => "Makefile",
    "man"                              => "Man",
    "markdown"                         => "Markdown",
    "mediawiki"                        => "Mediawiki",
    "mel"                              => "MEL",
    "mips"                             => "MIPS Assembler",
    "mod_perl"                         => "mod_perl",
    "modula-3"                         => "Modula-3",
    "moinmoin"                         => "MoinMoin",
    "mootools"                         => "MooTools",
    "movable_type"                     => "Movable Type",
    "multimarkdown"                    => "MultiMarkdown",
    "objective-c"                      => "Objective-C",
    "objective-c++"                    => "Objective-C++",
    "ocaml"                            => "OCaml",
    "ocamllex"                         => "OCamllex",
    "ocamlyacc"                        => "OCamlyacc",
    "opengl"                           => "OpenGL",
    "pascal"                           => "Pascal",
    "perl"                             => "Perl",
    "php"                              => "PHP",
    "plain_text"                       => "Plain Text",
    "pmwiki"                           => "PmWiki",
    "postscript"                       => "Postscript",
    "processing"                       => "Processing",
    "prolog"                           => "Prolog",
    "property_list"                    => "Property List",
    "python"                           => "Python",
    "python_django"                    => "Python (Django)",
    "qmake_project"                    => "qmake Project file",
    "qt_c++"                           => "Qt C++",
    "quake3_config"                    => "Quake Style .cfg",
    "r"                                => "R",
    "r_console"                        => "R Console",
    "ragel"                            => "Ragel",
    "rd_r_documentation"               => "Rd (R Documentation)",
    "regexp"                           => "Regular Expression",
    "regular_expressions_oniguruma"    => "Regular Expressions (Oniguruma)",
    "regular_expressions_python"       => "Regular Expressions (Python)",
    "release_notes"                    => "Release Notes",
    "remind"                           => "Remind",
    "restructuredtext"                 => "reStructuredText",
    "rez"                              => "Rez",
    "ruby"                             => "Ruby",
    "ruby_experimental"                => "Ruby Experimental",
    "ruby_on_rails"                    => "Ruby on Rails",
    "s5"                               => "S5 Slide Show",
    "scheme"                           => "Scheme",
    "scilab"                           => "Scilab",
    "setext"                           => "Setext",
    "shell-unix-generic"               => "Shell Script (Bash)",
    "slate"                            => "Slate",
    "smarty"                           => "Smarty",
    "sql"                              => "SQL",
    "sql_rails"                        => "SQL (Rails)",
    "ssh-config"                       => "SSH Config",
    "standard_ml"                      => "Standard ML",
    "strings_file"                     => "Strings File",
    "subversion_commit_message"        => "svn-commit.tmp",
    "sweave"                           => "SWeave",
    "swig"                             => "SWIG",
    "tcl"                              => "Tcl",
    "template_toolkit"                 => "Template Toolkit",
    "tex"                              => "TeX",
    "tex_math"                         => "TeX Math",
    "textile"                          => "Textile",
    "tsv"                              => "TSV",
    "twiki"                            => "Twiki",
    "txt2tags"                         => "Txt2tags",
    "vectorscript"                     => "Vectorscript",
    "xhtml_1.0"                        => "XHTML 1.0 Strict",
    "xml"                              => "XML",
    "xml_strict"                       => "XML strict",
    "xsl"                              => "XSL",
    "yaml"                             => "YAML",
    "yui_javascript"                   => "Javascript YUI",
}

end
