require File.dirname(__FILE__) + '/test_helper'
require 'thread_safe_hash'

class ThreadSafeHashTest < Test::Unit::TestCase

  def setup
    @hash = ThreadSafeHash.new
  end

  def test_initialize_sets_empty_hash
    assert_equal ({}),@hash.data
  end

  def test_can_set_data
    key = "key"
    value = "value"
    @hash[key] = value
    assert_equal value,@hash[key]
  end

  def test_has_key_returns_true_when_key_exists
    key = "key"
    @hash[key] = "something"
    assert @hash.has_key?(key)
  end

  def test_has_key_returns_false_when_key_value_is_nil
    key = "key"
    @hash[key] = nil
    assert !@hash.has_key?(key)
  end

  def test_eql_returns_false_if_not_thread_safe_hash_is_passed
    assert !@hash.eql?("not a thread safe hash")
  end

  def test_eql_returns_false_if_keys_array_are_different
    other = ThreadSafeHash.new
    other["a"] = 1
    @hash["b"] = 1
    assert !@hash.eql?(other)
  end

  def test_eql_returns_false_if_values_are_different_for_same_key
    other = ThreadSafeHash.new
    other["a"] = 1
    @hash["a"] = 2
    assert !@hash.eql?(other)
  end
  
  def test_eql_returns_true_if_key_value_pairs_are_all_identical
    other = ThreadSafeHash.new
    other["a"] = 1
    @hash["a"] = 1
    assert @hash.eql?(other)
  end

end