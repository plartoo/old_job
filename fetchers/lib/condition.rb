class Condition

  def initialize(attr, value)
    @attr = attr
    @value = value
  end

  def is_regex?
    @value.is_a? Regexp
  end

  def get_xpath_selector
    "[@" + get_selector + "]"
  end

  def get_css_selector
    "[" + get_selector + "]"
  end

  def get_selector
    is_regex? ? @attr.to_s : %Q(#{@attr}="#{@value}")
  end

  def matches?(node)
    !is_regex? || node[@attr] =~ @value
  end    

end
