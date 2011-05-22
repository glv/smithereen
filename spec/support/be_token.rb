module CustomSmithereenMatchers
  class BeLexerToken
    def initialize(type, text, from, to)
      @type, @text, @from, @to = type, text, from, to
    end
    def matches?(token)
      @token = token
      (        token.type == @type       ) &&
      (@text ? token.text == @text : true) &&
      (@from ? token.from == @from : true) &&
      (@to   ? token.to   == @to   : true)
    end
    def failure_message_for_should
      "expected #{@token} to be #{Smithereen::LexerToken.new(@type, @text, @from, @to)}"
    end
    def failure_message_for_should_not
      "expected #{@token} not to be #{Smithereen::LexerToken.new(@type, @text, @from, @to)}"
    end
  end
  def be_lexer_token(type, text=nil, from=nil, to=nil)
    BeLexerToken.new(type, text, from, to)
  end
end
