require File.join(File.dirname(__FILE__),"test_helper")
require File.join(File.dirname(__FILE__),'..','managers','saksfifthavenue')

class AdditionalCommandsTest < Test::Unit::TestCase

  def setup
    @manager = Saksfifthavenue.new({})
  end

  def test_assert_equal_price_raises_error_on_non_matching_strings
    assert_raise CheckoutManager::AssertionError do
      @manager.assert_equal_price("some price", "some other price")
    end
  end

  def test_assert_equal_price_raises_error_on_two_unequal_non_numeric_strings
    one = "what"
    two = "something"
    assert_raise CheckoutManager::AssertionError do
      @manager.assert_equal_price(one,two)
    end
    assert_raise CheckoutManager::AssertionError do
      @manager.assert_equal_price(two,one)
    end
  end

  def test_assert_equal_price_raises_error_on_empty_string_and_not_empty_string
    empty = ""
    not_empty = "something"
    assert_raise CheckoutManager::AssertionError do
      @manager.assert_equal_price(empty, not_empty)
    end
    assert_raise CheckoutManager::AssertionError do
      @manager.assert_equal_price(not_empty,empty)
    end
  end

  def test_assert_equal_price_doesnt_raise_error_on_valid_match
    one = "$120.00"
    two = "120.00"
    assert_nothing_raised do
      @manager.assert_equal_price(one,two)
    end
    assert_nothing_raised do
      @manager.assert_equal_price(two,one)
    end
  end

  def test_assert_equal_price_does_not_raise_error_on_invalid_match_plus_more
    one = "$120"
    two = "120.00"
    assert_nothing_raised do
      @manager.assert_equal_price(one,two)
    end
    assert_nothing_raised do
      @manager.assert_equal_price(two,one)
    end
  end

  def test_assert_equal_price_raises_error_on_unmatched_nil_values
    one = nil
    two = "120.00"
    assert_raise CheckoutManager::AssertionError do
      @manager.assert_equal_price(one,two)
    end
    assert_raise CheckoutManager::AssertionError do
      @manager.assert_equal_price(two,one)
    end
  end

  def test_assert_equal_price_doesnt_raise_error_on_nil_and_empty_string
    one = nil
    two = ""
    assert_nothing_raised do
      @manager.assert_equal_price(one,two)
    end
    assert_nothing_raised do
      @manager.assert_equal_price(two,one)
    end
  end
end
