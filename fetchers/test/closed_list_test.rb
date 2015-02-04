require File.dirname(__FILE__) + '/test_helper'
require 'closed_list'

class ClosedListTest < Test::Unit::TestCase

  def setup
    @list = ClosedList.new
  end

  def test_init_sets_variables
    assert_equal [], @list.data
  end

  def test_push_adds_param
    @list << 'a'
    assert_equal 1, @list.size
  end

  def test_push_keeps_list_uniq
    @list << 'a'
    assert_equal 1, @list.size
    @list << 'a'
    assert_equal 1, @list.size
  end

  def test_size_returns_correct_number
    assert_equal 0, @list.size
    @list << 'a'
    assert_equal 1, @list.size
  end

  def test_include_returns_true_when_it_has_item
    str = "something"
    assert !@list.include?(str)
    @list << str
    assert @list.include?(str)
  end
end
