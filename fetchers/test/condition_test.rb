require 'test_helper'

class ConditionTest < Test::Unit::TestCase

  def test_get_selector
    c = Condition.new "id", "foobar"
    assert_equal c.get_selector, 'id="foobar"'
  end

end
