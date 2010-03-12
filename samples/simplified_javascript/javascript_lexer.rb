require 'radish'

module RadishSamples
  class SimplifiedJavaScriptLexer < Radish::Lexer
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
      produce_next_token_with_regexps
    end

    def produce_next_token_with_regexps
      return nil if i >= length
    
      rest = s[i..-1]
      case rest
      when /\A\s+/m
        move $&.size
        produce_next_token
      when /\A[[:alpha:]]\w*/m
        make_token(:name, $&)
      when /\A\d+(\.\d+)?([eE]\d+)?/m
        # ??? do finiteness check
        make_token(:number, $&)
      when /\A(['"])(.*?)\1/
        str_source_size = $&.size
        str = $2.gsub(%r{\\[bfnrt]}) do |m|
          case m[1]
          when ?b then ?\b.chr
          when ?f then ?\f.chr
          when ?n then ?\n.chr
          when ?r then ?\r.chr
          when ?t then ?\t.chr
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
          return make_token(:name, str)
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

          if c && "eE".include?(c)
            move
            str << c
            c = s[i]
            if c && "-+".include?(c)
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
          
          return make_token(:number, str)
          # n = float ? str.to_f : str.to_i
          # return make_token(:number, n)
          # ??? Something about checking for finiteness here

        when "'\"".include?(c)
          str = ''
          q = c
          move
          loop do
            c = s[i]
            if c < ?\ 
              if c.nil? || "\n\r".include?(c)
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
              when ?b then ?\b
              when ?f then ?\f
              when ?n then ?\n
              when ?r then ?\r
              when ?t then ?\t
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
          return make_token(:string, str)
          c = s[i]

        when c == ?/ && s[i+1] == ?/
          move
          loop do 
            c = s[i]
            break if c.nil? || '\n\r'.include(c)
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
          return make_token(:operator, str)
        else
          move
          return make_token(:operator, c)
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
