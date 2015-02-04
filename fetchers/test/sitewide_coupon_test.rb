require 'test_helper'

class SitewideCouponTest < Test::Unit::TestCase

  def setup
    @options = {}
    @options["message"] = "message"
    @options["min_price"] = "10.00"
    @options["discount_type"] = 1
    @options["amount"] = "0.25"
    @options["exclude_brands"] = true
    @options[:brands] = [{:bm => 100, :dept_bm => 0}]
    @options["exclude_department_clothing_types"] = false
    @options[:clothing_types] = [{:bm => 12, :dept_bm => 0}]
    @options["start_date"] = Date.parse("2009-08-01")
    @options["end_date"] = Date.parse("2009-08-06")
    @coupon = SitewideCoupon.new @options

    @item = Item.new
    @item.sale_price = "20.00"
    @item.dept = :womens
    @item.clothing_type = ClothingType[:INTIMATES,@item.dept]
    @item.brand_bm = 50

    Date.stubs(:today).returns(Date.parse("2009-08-04"))
  end

  def test_date_matching
    assert @coupon.valid_on?(Date.parse("2009-08-04"))
    assert !@coupon.valid_on?(Date.parse("2009-07-30"))
    assert !@coupon.valid_on?(Date.parse("2009-08-09"))
  end

  def test_min_price
    assert @coupon.applies_to?(@item)
    @item.sale_price = "9.00"
    assert @coupon.applies_to?(@item)
  end

  def test_brand_matching
    assert @coupon.applies_to?(@item)
    @item.brand_bm = 100
    assert !@coupon.applies_to?(@item)
  end

  def test_clothing_type_matching
    assert @coupon.applies_to?(@item)
    @item.clothing_type = ClothingType[:BAG,:womens]
    assert !@coupon.applies_to?(@item)
  end

  def test_percent_discount
    @coupon.apply_discount!(@item)
    assert_equal("15.00", @item.sale_price)
  end
  
  def test_absolute_discount
    @options["discount_type"] = "0"
    @options["amount"] = "6.00"
    coupon = SitewideCoupon.new @options
    coupon.apply_discount!(@item)
    assert_equal("14.00", @item.sale_price)
  end

  def test_check_price_range_returns_false_when_range_type_percent_and_lower_than_min
    item = mock('item') do
      expects(:original_price).returns(50).twice
      expects(:sale_price).returns(40)
    end
    options = {
      "range_type" => 1,
      "min_range" => "0.25",
    }
    assert !SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_false_when_range_type_percent_and_higher_than_max
    item = mock('item') do
      expects(:original_price).returns(100).twice
      expects(:sale_price).returns(55)
    end
    options = {
      "range_type" => 1,
      "max_range" => "0.25",
    }
    assert !SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_true_when_range_type_percent_and_inside_range
    item = mock('item') do
      expects(:original_price).returns(50).twice
      expects(:sale_price).returns(30)
    end
    options = {
      "range_type" => 1,
      "min_range" => "0.10",
      "max_range" => "0.80",
    }
    assert SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_false_when_range_type_amount_and_original_price_lower_than_min
    item = mock('item') do
      expects(:original_price).returns(30)
      expects(:sale_price).returns(20)
      expects(:current_price).returns(20)
    end
    options = {
      "range_type" => 2,
      "range_of_which_price" => 1,
      "min_range" => "35.00",
    }
    assert !SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_false_when_range_type_amount_and_sale_price_lower_than_min
    item = mock('item') do
      expects(:original_price).returns(50)
      expects(:sale_price).returns(30)
      expects(:current_price).returns(30)
    end
    options = {
      "range_type" => 2,
      "range_of_which_price" => 2,
      "min_range" => "35.00",
    }
    assert !SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_true_when_range_type_amount_and_original_price_higher_than_min
    item = mock('item') do
      expects(:original_price).returns(50)
      expects(:sale_price).returns(30)
      expects(:current_price).returns(30)
    end
    options = {
      "range_type" => 2,
      "range_of_which_price" => 1,
      "min_range" => "35.00",
    }
    assert SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_true_when_range_type_amount_and_sale_price_higher_than_min
    item = mock('item') do
      expects(:original_price).returns(60)
      expects(:sale_price).returns(50)
      expects(:current_price).returns(50)
    end
    options = {
      "range_type" => 2,
      "range_of_which_price" => 2,
      "min_range" => "35.00",
    }
    assert SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_true_when_range_type_amount_and_original_price_inside_range
    item = mock('item') do
      expects(:original_price).returns(50)
      expects(:sale_price).returns(30)
      expects(:current_price).returns(30)
    end
    options = {
      "range_type" => 2,
      "range_of_which_price" => 1,
      "min_range" => "10",
      "max_range" => "80",
    }
    assert SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_true_when_range_type_amount_and_sale_price_inside_range
    item = mock('item') do
      expects(:original_price).returns(80)
      expects(:sale_price).returns(50)
      expects(:current_price).returns(50)
    end
    options = {
      "range_type" => 2,
      "range_of_which_price" => 2,
      "min_range" => "10",
      "max_range" => "80",
    }
    assert SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_true_when_range_type_amount_max_equals_original_price
    item = mock('item') do
      expects(:original_price).returns(50)
      expects(:sale_price).returns(30)
      expects(:current_price).returns(30)
    end
    options = {
      "range_type" => 2,
      "range_of_which_price" => 1,
      "min_range" => "10",
      "max_range" => "50",
    }
    assert SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_true_when_range_type_amount_min_equals_original_price
    item = mock('item') do
      expects(:original_price).returns(80)
      expects(:sale_price).returns(50)
      expects(:current_price).returns(50)
    end
    options = {
      "range_type" => 2,
      "range_of_which_price" => 1,
      "min_range" => "80",
      "max_range" => "100",
    }
    assert SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_true_when_range_type_amount_max_equals_sale_price
    item = mock('item') do
      expects(:original_price).returns(80)
      expects(:sale_price).returns(50)
      expects(:current_price).returns(50)
    end
    options = {
      "range_type" => 2,
      "range_of_which_price" => 2,
      "min_range" => "30",
      "max_range" => "50",
    }
    assert SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_true_when_range_type_amount_min_equals_sale_price
    item = mock('item') do
      expects(:original_price).returns(80)
      expects(:sale_price).returns(50)
      expects(:current_price).returns(50)
    end
    options = {
      "range_type" => 2,
      "range_of_which_price" => 2,
      "min_range" => "50",
      "max_range" => "60",
    }
    assert SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_true_when_range_type_percent_max_equals_percentage_discount
    item = mock('item') do
      expects(:original_price).returns(100).twice
      expects(:sale_price).returns(50)
    end
    options = {
      "range_type" => 1,
      "min_range" => "0.30",
      "max_range" => "0.50",
    }
    assert SitewideCoupon.new(options).check_price_range(item)
  end

  def test_check_price_range_returns_true_when_range_type_percent_min_equals_percentage_discount
    item = mock('item') do
      expects(:original_price).returns(100).twice
      expects(:sale_price).returns(70)
    end
    options = {
      "range_type" => 1,
      "min_range" => "0.30",
      "max_range" => "0.50",
    }
    assert SitewideCoupon.new(options).check_price_range(item)
  end

  def test_apply_discount_adds_notice
    options = {
      "message" => "Hello World"
    }

    coupon = SitewideCoupon.new(options)
    coupon.stubs(:applies_to?).returns(true)
    item = mock('item') do
      expects(:notice)
      expects(:original_price).returns(100)
      expects(:sale_price).returns(70).twice
      expects(:sale_price=)
      expects(:current_price).returns(70)
      
      # will fail if parameter isn't right
      expects(:notice=).with("Hello World")
    end
    coupon.apply_discount!(item)
  end

  def test_apply_discount_uses_current_price_as_parameter
    options = {
      "discount_which_price" => 0,
      "message" => "Hello World"
    }

    coupon = SitewideCoupon.new(options)
    coupon.stubs(:applies_to?).returns(true)
    to_return = 70
    item = mock('item') do
      expects(:notice)
      expects(:notice=).with("Hello World")
      expects(:original_price).returns(100)
      expects(:sale_price).returns(80).twice
      expects(:sale_price=)
      expects(:current_price).returns(to_return)
    end
      
    # will fail if parameter isn't right
    coupon.stubs(:get_new_sale_price).with(to_return)
    coupon.apply_discount!(item)
  end

  def test_apply_discount_uses_original_price_as_parameter
    options = {
      "discount_which_price" => 1,
      "message" => "Hello World"
    }

    coupon = SitewideCoupon.new(options)
    coupon.stubs(:applies_to?).returns(true)
    to_return = 100
    item = mock('item') do
      expects(:notice)
      expects(:notice=).with("Hello World")
      expects(:original_price).returns(to_return)
      expects(:sale_price).returns(70).twice
      expects(:sale_price=)
      expects(:current_price).returns(60)
    end

    # will fail if parameter isn't right
    coupon.stubs(:get_new_sale_price).with(to_return)
    coupon.apply_discount!(item)
  end

  def test_apply_discount_uses_sale_price_as_parameter
    options = {
      "discount_which_price" => 2,
      "message" => "Hello World"
    }

    coupon = SitewideCoupon.new(options)
    coupon.stubs(:applies_to?).returns(true)
    to_return = 70
    item = mock('item') do
      expects(:notice)
      expects(:notice=).with("Hello World")
      expects(:original_price).returns(100)
      expects(:sale_price).returns(to_return).twice
      expects(:sale_price=)
      expects(:current_price).returns(60)
    end

    # will fail if parameter isn't right
    coupon.stubs(:get_new_sale_price).with(to_return)
    coupon.apply_discount!(item)
  end
end

