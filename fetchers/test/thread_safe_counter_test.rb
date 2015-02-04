require File.dirname(__FILE__) + '/test_helper'

class ThreadSafeCounterTest < Test::Unit::TestCase

  def setup
    @counter = ThreadSafeCounter.new
  end

  def test_increment_ups_count
    assert_equal 0, @counter.value
    assert_equal 1,@counter.increment
    assert_equal 1,@counter.value
  end

  def test_decrement_lowers_count
    assert_equal 0, @counter.value
    @counter.increment
    assert_equal 0,@counter.decrement
    assert_equal 0,@counter.value
  end

  def test_decrement_wont_go_below_zero
    assert_equal 0, @counter.value
    assert_equal 0,@counter.decrement
    assert_equal 0,@counter.decrement
    assert_equal 0, @counter.value
  end

  def test_value_returns_correct_value
    assert_equal 0, @counter.value
    num = 5
    1.upto(num){|n|
      @counter.increment
      assert_equal n, @counter.value
    }
  end

  def test_to_s_returns_string_version_of_value
    assert_equal 0, @counter.value
    assert_equal "0",@counter.to_s
  end



end