
def rareClass(word)
  case word
    when /\d+/
      "__RARE_NUMBERS__"
    when /^[\dA-Z]+$/
      "__RARE_ALPHA_NUMBERS__"
    when /^[A-Z]+$/
      "__RARE_CAPITAL__"
    when /^[a-z]+[A-Z]$/
      "__RARE_LAST_CAPITAL__"
    when /[a-z][A-Z]/
      "__RARE_MIXED_CASE__"
    when /[\d\w]+/
      "__RARE_ALPHA_NUMBERS2__"
    else
      "__RARE__"
  end
end