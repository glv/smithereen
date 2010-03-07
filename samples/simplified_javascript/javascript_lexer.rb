$: << File.dirname(__FILE__) + '/../../lib'
$: << File.dirname(__FILE__)
require 'radish'

module RadishSamples
  class JavaScriptLexer < Radish::Lexer
    LOWER = ?a .. ?z
    UPPER = ?A .. ?Z
    DIGIT = ?0 .. ?9

    attr_reader :prefix, :suffix
    attr_accessor :i
    attr_reader :s, :result, :length

    def op_re
      @op_re ||= build_op_re
    end
    
    def build_op_re
      Regexp.new("\\A[#{Regexp.escape(@prefix)}][#{Regexp.escape(@suffix)}]*", 
                 Regexp::MULTILINE)
    end

    def prefix=(p)
      @prefix = p
      @op_re = nil
    end

    def suffix=(s)
      @suffix = s
      @op_re = nil
    end

    protected :s, :result, :length, :op_re, :build_op_re, :i, :i=

    def initialize(s)
      super(s)
      self.prefix = '<>+-&|=!'
      self.suffix = '=>&:|' 
    end

    def produce_next_token
      return nil if i >= length
    
      rest = s[i..-1]
      case rest
      when /\A\s+/m
        move $&.size
        produce_next_token
      when /\A[[:alpha:]]\w*/m
        puts "name"
        make_token(:name, $&)
      when /\A\d+(\.\d+)?([eE]\d+)?/m
        # ??? do finiteness check
        make_token(:number, $&)
      when /\A(['"])(.*?)\1/
        str_source_size = $&.size
        str = $2.gsub(%r{\\[bfnrt]}) do |m|
          case m[1]
          when ?b: ?\b.chr
          when ?f: ?\f.chr
          when ?n: ?\n.chr
          when ?r: ?\r.chr
          when ?t: ?\t.chr
            # ??? do unicode somehow
          end
        end
        make_token(:string, str, str_source_size)
      when %r{\A//.*}
        puts "comment"
        move $&.size
        produce_next_token
      when op_re
        make_token(:operator, $&)
      when /\A./
        make_token(:operator, $&)
      else
        puts "yikes!"
        # ??? report error somehow
      end
    end

    def produce_next_token_without_regexps
      return nil if i >= length

      c = s[i]
      while c
        from = i

        case 
        when ' ' === c
          move
          c = s[i]
        when LOWER === c, UPPER === c
          str = c.chr
          move
          loop do
            c = s[i]
            break unless is_name_char(c)
            str << c
            move
          end
          return LexerToken.new(:name, str, from, i)
        when DIGIT === c
          str = c.chr
          move
          float = false
          loop do
            c = s[i]
            break unless DIGIT === c
            move
            str << c
          end

          if c == '.'
            move
            str << c
            loop do
              c = s[i]
              break unless DIGIT === c
              move
              str << c
            end
            float = true
          end

          if "eE".include?(c)
            move
            str << c
            c = s[i]
            if "-+".include?(c)
              move
              str << c
            end
            unless DIGIT === c
              raise LexerException.new("Bad exponent", str, from, i) 
            end

            begin
              move
              str << c
              c = s[i]
            end while DIGIT === c
          end

          if LOWER === c
            str << c
            move
            raise LexerException.new("Bad number", str, from, i)
          end

          n = float? ? str.to_f : str.to_i
          return LexerToken.new(:number, n, from, i)
          # ??? Something about checking for finiteness here

        when "'\"".include?(c)
          str = ''
          q = c
          move
          loop do
            c = s[i]
            if c < ?\ 
              if "\n\r".include?(c) || c.nil?
                msg = "Unterminated string."
              else
                msg = "Control character in string."
              end
              raise LexerException.new(msg, str, from, i)
            end

            break if c == q

            if c == ?\\
              move
              if i >= length
                raise LexerException.new("Unterminated string", str, from, i)
              end
              c = s[i]
              c = case c
              when ?b: ?\b
              when ?f: ?\f
              when ?n: ?\n
              when ?r: ?\r
              when ?t: ?\t
                # 		when ?u
                # 		  if i >= length
                # 		    raise LexerException.new("Unterminated string", str, from, i)
                # 		  end
                # 		  code = s[i+1, 4].to_i(16)
                # 		  # ??? Finiteness check here too
                #		  move 4
                # 		  unicode_char(code)
              else
                raise LexerException.new("Unrecognized escape sequence", str, from, i)
              end
            end
            str << c
            move
          end
          move
          return LexerToken.new(:string, str, from, i)
          c = s[i]

        when c == ?/ && s[i+1] == ?/
          move
          loop do 
            c = s[i]
            break if '\n\r'.include(c) || c.nil?
            move
          end

        when prefix.index(c)
          str = c
          move
          while i < length
            c = s[i]
            break if suffix.index(c)
            str << c
            move
          end
          return LexerToken.new(:operator, str, from, i)
        else
          move
          return LexerToken.new(:operator, c, from, i)
          c = s[i]
        end
      end

      result
    end

    def is_name_char(c)
      LOWER === c || UPPER === c || DIGIT === c || ' ' === c
    end
  end
end
