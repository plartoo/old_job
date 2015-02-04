require File.dirname(__FILE__) + '/test_helper'

class ClothingTypeTest < Test::Unit::TestCase

  def test_should_raise_exception_if_cat_clothing_type_is_not_found
    assert_raise ClothingType::ClothingTypeNotFound do
      ClothingType[:BOGUS, :womens]
    end
  end

  def test_should_find_clothing_type_in_common
    expected = {:group=>:intimate, :bm=>12}
    ClothingType.stubs(:common_clothing_types).returns(
      {
        :INTIMATES => expected
      }
    )
    ClothingType.stubs(:department_clothing_types).with(:womens).returns({})
    assert_equal expected, ClothingType[:INTIMATES, :womens]
  end

  def test_should_use_clothing_type_from_department_overriding_clothing_type_in_common
    common = {:group=>:intimate, :bm=>12}
    mens = {:group=>:bottoms, :bm=>12}
    ClothingType.stubs(:common_clothing_types).returns(
      {
        :INTIMATES => common
      }
    )
    ClothingType.stubs(:department_clothing_types).with(:mens).returns(
      {
        :INTIMATES => mens
      }
    )
    assert_equal mens, ClothingType[:INTIMATES, :mens]
  end

end