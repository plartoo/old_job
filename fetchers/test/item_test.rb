require File.dirname(__FILE__) + '/test_helper'

class ItemTest < Test::Unit::TestCase

  def setup
    @item = Item.new
    @item.dept = "womens"
    @item.description = "foo"
    @item.product_url = "bar"
    @item.product_image = ItemImage.new("baz", 100, 100, 125)
    @item.original_price = "9"
    @item.sale_price = "5"
    @item.clothing_type = {:bm => 1}
    @item.vendor_key = ""
    @item.vendor_name = "vendor"
    @item.brand_bm = 0    
    @item.scc = [{:size_type_bm => 6, :color => "Black", :size_bm => 2}]
  end

  def test_hash
    item = @item.to_hash
    assert_equal(item[:description], @item.description)
    assert_equal(item[:dynamic][:original_price], @item.original_price)
    assert_equal(item[:product_url], @item.product_url)
  end

  def test_equals
    item = Item.new
    item.description = "foo"
    item.product_url = "bar"
    item.product_image = ItemImage.new("baz", 100, 100, 125)
    item.original_price = "9"
    item.sale_price = "5"
    item.clothing_type = {:bm => 1}
    item.vendor_key = ""
    item.brand_bm = 0
    item.vendor_name = "vendor"
    item.scc = @item.scc

    assert_equal(true, item == @item)
    assert_equal(true, item.eql?(@item))
  end

  def test_load_from_hash
    item = Item.load_from_hash(@item.to_hash)
    
  end

  def test_validity
    assert_equal(false, Item.new.valid?)
    assert_equal(true, @item.valid?)
  end

  def test_price_parse
    @item.original_price = "now $19.00"
    assert_equal("19.00", @item.original_price)

    @item.original_price = "   1,115.67"
    assert_equal("1115.67", @item.original_price)
  end

  def test_eql_eql_when_only_one_item_has_nil_scc
    item_1 = Item.new
    item_2 = Item.new
    item_1.scc = @item.scc
    assert_nil item_2.scc
    assert_nothing_raised do
      item_1 == item_2
    end
    assert item_1 != item_2
  end

  def test_scc_equals_validates_scc
    yml = <<-EOS
      - :size_type_bm: 6
        :color: Black
        :size_bm: 2
      - :size_type_bm: 6
        :color: Black
        :size_bm: 3
      - :size_type_bm: 6
        :color: Black
        :size_bm: 1
    EOS
    scc = YAML.load(yml)
    item = Item.new
    assert_nothing_raised do
      item.scc = @item.scc
    end
    assert_nothing_raised do
      item.scc = scc
    end
    doc = Nokogiri::XML::Document.new
    scc.last.merge!(:color => Nokogiri::XML::Attr.new(doc,"foo"))
    assert_raises(Item::InvalidSCCException) do
      item.scc = scc
    end
  end

  def test_class_variable_for_validating_sale_price_defaults_to_true
    assert Item.validate_sale_price
  end

  def test_class_variable_for_validating_sale_price_can_be_set_and_retrieved
    Item.validate_sale_price = false
    assert !Item.validate_sale_price
    Item.validate_sale_price = true
  end

  def test_valid_check_will_check_the_existence_of_sale_price_by_default
    @item.sale_price = nil
    assert_equal false,@item.valid?
    @item.sale_price = "5"
    assert_equal true,@item.valid?
  end

  def test_valid_check_will_not_check_the_existence_of_sale_price_if_validate_sale_price_variable_is_set_false
    Item.validate_sale_price = false
    @item.sale_price = nil
    assert_equal true,@item.valid?
    @item.sale_price = "5"
  end

  def test_unique_id_returns_concatenated_vendor_key_and_name_hashed
    key = "some_vendor_key"
    name = "some_vendor_name"
    @item.vendor_key = key
    @item.vendor_name = name
    expected = Digest::MD5.hexdigest("#{key}#{name}")
    assert_equal expected, @item.unique_id
  end

  def test_unique_id_raises_error_if_vendor_key_is_nil
    @item.vendor_key = nil
    assert_raise Item::InvalidVendorKey do
      @item.unique_id
    end
  end
end

