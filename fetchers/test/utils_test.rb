require File.dirname(__FILE__) + '/test_helper'

class UtilsTest < Test::Unit::TestCase

  def setup
    Utils.i18n_version = 'us'
  end

  def test_convert_price_to_float_deletes_comma_and_returns_float_when_input_has_commas
    assert_equal 1234.0, Utils.convert_price_to_float("1,234.00")
  end

  def test_convert_price_to_float_deletes_comma_and_returns_float_when_input_has_no_commas
    assert_equal 1234.0, Utils.convert_price_to_float("1234.00")
  end

  def test_convert_price_to_float_deletes_comma_and_returns_float_when_input_has_no_decimals
    assert_equal 1234.0, Utils.convert_price_to_float("1234")
  end

  def test_get_price_str_parses_price_strings_correctly_for_us_dollar
    us_str = ["$1234.00", "$ 1234.00", "$.50", "$ 1,234.00", "$0.50", "$ 0.50", "$ 0.5"]
    expected_us_price = ["1234.00","1234.00",".50","1234.00", "0.50", "0.50", "0.5"]
    us_str.each_with_index do |str,i|
      assert_equal expected_us_price[i], Utils.get_price_str(str)
    end
  end

  def test_get_price_str_parses_price_strings_correctly_for_gbp
    Utils.i18n_version = 'uk'
    us_str = ["£1234.00", "£ 1234.00", "£.50", "£ 1,234.00", "£0.50", "£ 0.50", "£ 0.5"]
    expected_us_price = ["1234.00","1234.00",".50","1234.00", "0.50", "0.50", "0.5"]
    us_str.each_with_index do |str,i|
      assert_equal expected_us_price[i], Utils.get_price_str(str)
    end
    Utils.i18n_version = 'us'
end

end
