require 'asciidoctor'
require 'asciidoctor/extensions'
require 'asciidoctor/converter/docbook5'
require 'asciidoctor/converter/html5'
require 'asciidoctor/converter/manpage'
require 'parslet'

module Git
  module Documentation

    class AdocSynopsisQuote < Parslet::Parser
      # parse a string like "git add -p [--root=<path>]" as series of tokens keywords, grammar signs and placeholders
      # where placeholders are UTF-8 words separated by '-', enclosed in '<' and '>'
      rule(:space)      { match('[\s\t\n ]').repeat(1) }
      rule(:space?)     { space.maybe }
      rule(:keyword) { match('[-a-zA-Z0-9:+=~@,\./_^\$\'"\*%!{}#]').repeat(1) }
      rule(:placeholder) { str('<') >> match('[[:word:]]|-').repeat(1) >> str('>') }
      rule(:opt_or_alt) { match('[\[\] |()]') >> space? }
      rule(:ellipsis) { str('...') >> match('\]|$').present? }
      rule(:grammar) { opt_or_alt | ellipsis }
      rule(:ignore) { match('[\'`]') }

      rule(:token) { grammar.as(:grammar) | placeholder.as(:placeholder) | space.as(:grammar) | ignore.as(:ignore) | keyword.as(:keyword)}
      rule(:tokens) { token.repeat(1) }
      root(:tokens)
    end

    class EscapedSynopsisQuote < Parslet::Parser
      rule(:space)      { match('[\s\t\n ]').repeat(1) }
      rule(:space?)     { space.maybe }
      rule(:keyword) { match('[-a-zA-Z0-9:+=~@,\./_\^\$\'"\*%!{}#]').repeat(1) }
      rule(:placeholder) { str('&lt;') >> match('[[:word:]]|-').repeat(1) >> str('&gt;') }
      rule(:opt_or_alt) { match('[\[\] |()]') >> space? }
      rule(:ellipsis) { str('...') >> match('\]|$').present? }
      rule(:grammar) { opt_or_alt | ellipsis }
      rule(:ignore) { match('[\'`]') }

      rule(:token) { grammar.as(:grammar) | placeholder.as(:placeholder) | space.as(:grammar) | ignore.as(:ignore) | keyword.as(:keyword)}
      rule(:tokens) { token.repeat(1) }
      root(:tokens)
    end

    class SynopsisQuoteToAdoc < Parslet::Transform
      rule(grammar: simple(:grammar)) { grammar.to_s }
      rule(keyword: simple(:keyword)) { "{empty}`#{keyword}`{empty}" }
      rule(placeholder: simple(:placeholder)) { "__#{placeholder}__" }
      rule(ignore: simple(:ignore)) { '' }
    end

    class SynopsisQuoteToMan < Parslet::Transform
      ESC_BS = Asciidoctor::Converter::ManPageConverter::ESC_BS
      rule(grammar: simple(:grammar)) { grammar.to_s }
      rule(keyword: simple(:keyword)) { %(<#{ESC_BS}fB>#{keyword}<#{ESC_BS}fP>) }
      rule(placeholder: simple(:placeholder)) { %(<#{ESC_BS}fI>#{placeholder}<#{ESC_BS}fP>) }
      rule(ignore: simple(:ignore)) { '' }
    end

    class SynopsisQuoteToHtml5 < Parslet::Transform
      rule(grammar: simple(:grammar)) { grammar.to_s }
      rule(keyword: simple(:keyword)) { "<code>#{keyword}</code>" }
      rule(placeholder: simple(:placeholder)) { "<em>#{placeholder}</em>" }
      rule(ignore: simple(:ignore)) { '' }
    end

    class SynopsisQuoteToDocbook < Parslet::Transform
      rule(grammar: simple(:grammar)) { grammar.to_s }
      rule(keyword: simple(:keyword)) { "<literal>#{keyword}</literal>" }
      rule(placeholder: simple(:placeholder)) { "<emphasis>#{placeholder}</emphasis>" }
      rule(ignore: simple(:ignore)) { '' }
    end

    class SynopsisConverter
      def convert(parslet_parser, parslet_transform, reader, logger = nil)
        reader.lines.map do |l|
          parslet_transform.apply(parslet_parser.parse(l)).join
        end.join("\n")
      rescue Parslet::ParseFailed
        logger&.warn "synopsis parsing failed for '#{reader.lines.join(' ')}'"
        reader.lines.map do |l|
          parslet_transform.apply(placeholder: l)
        end.join("\n")
      end
    end

    class LinkGitProcessor < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl

      named :chrome

      def process(parent, target, attrs)
        prefix = parent.document.attr('git-relative-html-prefix')
        if parent.document.doctype == 'book'
          "<ulink url=\"#{prefix}#{target}.html\">" \
          "#{target}(#{attrs[1]})</ulink>"
        elsif parent.document.basebackend? 'manpage'
          create_inline parent, :quoted,
                        %(<#{Asciidoctor::Converter::ManPageConverter::ESC_BS}fB>#{target}<#{Asciidoctor::Converter::ManPageConverter::ESC_BS}fR>(#{attrs[1]}))
        elsif parent.document.basebackend? 'html'
          %(<a href="#{prefix}#{target}.html">#{target}(#{attrs[1]})</a>)
        elsif parent.document.basebackend? 'docbook'
          "<citerefentry>\n" \
            "<refentrytitle>#{target}</refentrytitle>" \
            "<manvolnum>#{attrs[1]}</manvolnum>\n" \
          "</citerefentry>"
        end
      end
    end

    class DocumentPostProcessor < Asciidoctor::Extensions::Postprocessor
      def process document, output
        if document.basebackend? 'docbook'
          mansource = document.attributes['mansource']
          manversion = document.attributes['manversion']
          manmanual = document.attributes['manmanual']
          new_tags = "" \
            "<refmiscinfo class=\"source\">#{mansource}</refmiscinfo>\n" \
            "<refmiscinfo class=\"version\">#{manversion}</refmiscinfo>\n" \
            "<refmiscinfo class=\"manual\">#{manmanual}</refmiscinfo>\n"
          output = output.sub(/<\/refmeta>/, new_tags + "</refmeta>")
        end
        output
      end
    end

    class SynopsisBlock < Asciidoctor::Extensions::BlockProcessor

      use_dsl
      named :synopsis
      parse_content_as :simple

      def process(parent, reader, attrs)
        outlines = SynopsisConverter.new.convert(AdocSynopsisQuote.new, SynopsisQuoteToAdoc.new, reader, parent.document.logger)
        create_block parent, :verse, outlines, attrs
      end
    end

    class GitDBConverter < Asciidoctor::Converter::DocBook5Converter

      extend Asciidoctor::Converter::Config
      register_for 'docbook5'

      def convert_inline_quoted node
        if (type = node.type) == :asciimath
          # NOTE fop requires jeuclid to process mathml markup
          asciimath_available? ? %(<inlineequation>#{(::AsciiMath.parse node.text).to_mathml 'mml:', 'xmlns:mml' => 'http://www.w3.org/1998/Math/MathML'}</inlineequation>) : %(<inlineequation><mathphrase><![CDATA[#{node.text}]]></mathphrase></inlineequation>)
        elsif type == :latexmath
          # unhandled math; pass source to alt and required mathphrase element; dblatex will process alt as LaTeX math
          %(<inlineequation><alt><![CDATA[#{equation = node.text}]]></alt><mathphrase><![CDATA[#{equation}]]></mathphrase></inlineequation>)
        elsif type == :monospaced
          SynopsisConverter.new.convert(EscapedSynopsisQuote.new, SynopsisQuoteToDocbook.new, node.text, node.document.logger)
        else
          open, close, supports_phrase = QUOTE_TAGS[type]
          text = node.text
          if node.role
            if supports_phrase
              quoted_text = %(#{open}<phrase role="#{node.role}">#{text}</phrase>#{close})
            else
              quoted_text = %(#{open.chop} role="#{node.role}">#{text}#{close})
            end
          else
            quoted_text = %(#{open}#{text}#{close})
          end
          node.id ? %(<anchor#{common_attributes node.id, nil, text}/>#{quoted_text}) : quoted_text
        end
      end
    end

    # register a html5 converter that takes in charge to convert monospaced text into Git style synopsis
    class GitHTMLConverter < Asciidoctor::Converter::Html5Converter

      extend Asciidoctor::Converter::Config
      register_for 'html5'

      def convert_inline_quoted node
        if node.type == :monospaced
          SynopsisConverter.new.convert(EscapedSynopsisQuote.new, SynopsisQuoteToHtml5.new, node.text, node.document.logger)
        else
          open, close, tag = QUOTE_TAGS[node.type]
          if node.id
            class_attr = node.role ? %( class="#{node.role}") : ''
            if tag
              %(#{open.chop} id="#{node.id}"#{class_attr}>#{node.text}#{close})
            else
              %(<span id="#{node.id}"#{class_attr}>#{open}#{node.text}#{close}</span>)
            end
          elsif node.role
            if tag
              %(#{open.chop} class="#{node.role}">#{node.text}#{close})
            else
              %(<span class="#{node.role}">#{open}#{node.text}#{close}</span>)
            end
          else
            %(#{open}#{node.text}#{close})
          end
        end
      end
    end

    class GitManpageConverter < Asciidoctor::Converter::ManPageConverter

      extend Asciidoctor::Converter::Config
      register_for 'manpage'

      def convert_inline_quoted node
        case node.type
        when :emphasis
          %(<#{ESC_BS}fI>#{node.text}</#{ESC_BS}fP>)
        when :strong
          %(<#{ESC_BS}fB>#{node.text}</#{ESC_BS}fP>)
        when :monospaced
          SynopsisConverter.new.convert(EscapedSynopsisQuote.new, SynopsisQuoteToMan.new, node.text, node.document.logger)
        when :single
          %[<#{ESC_BS}(oq>#{node.text}</#{ESC_BS}(cq>]
        when :double
          %[<#{ESC_BS}(lq>#{node.text}</#{ESC_BS}(rq>]
        else
          node.text
        end
      end
    end
  end
end



Asciidoctor::Extensions.register do
  inline_macro Git::Documentation::LinkGitProcessor, :linkgit
  block Git::Documentation::SynopsisBlock
  postprocessor Git::Documentation::DocumentPostProcessor
end
