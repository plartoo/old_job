module SevenForAllMankindUsSize # :nodoc:

  def match_within_girls_top(value, item)
    {
      '4/5'=>['4','4SLIM','5','5SLIM'],
      '5/6'=>['5','5SLIM','6','6SLIM'],
      '6/7'=>['6','6SLIM','7','7SLIM'],
      '7/8'=>['7','7SLIM','8','8SLIM'],
      '6X/7'=>['6PLUS','7', '7SLIM']
    }[value]
  end

  def match_within_boys_top(value, item)
    {
      '4/5'=>['4','4SLIM','5','5SLIM'],
      '5/6'=>['5','5SLIM','6','6SLIM'],
      '6/7'=>['6','6SLIM','7','7SLIM'],
      '7/8'=>['7','7SLIM','8','8SLIM'],
      '6X/7'=>['6HUSKY','7', '7SLIM']
    }[value]
  end

end