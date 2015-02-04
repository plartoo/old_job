require 'test_helper'

class SizeColorConfigurationTest < Test::Unit::TestCase
  def setup
    @scc1 = SizeColorConfiguration.new({:bm=>1,:type_bm=>2},"color")
    @scc2 = SizeColorConfiguration.new({:bm=>1,:type_bm=>2},"color")
    @scc3 = SizeColorConfiguration.new({:bm=>2,:type_bm=>2},"color")
  end
  def test_double_equal_for_same
    assert_equal @scc1,@scc2
  end
  def test_double_equal_for_different
    assert_not_equal @scc1,@scc3
  end

  def test_eql_for_same
    assert_equal true, @scc1.eql?(@scc2)
  end
  def test_eql_for_different
    assert_equal false, @scc1.eql?(@scc3)
  end

  def test_hash_same
    assert_equal @scc1.hash, @scc2.hash
  end
  def test_hash_different
    assert_not_equal @scc1.hash, @scc3.hash
  end

  def test_array_subtraction
    assert_equal [], [@scc1] - [@scc2]
  end
end
