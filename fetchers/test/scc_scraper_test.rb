require File.dirname(__FILE__) + '/test_helper'

class SCCScraperTest < Test::Unit::TestCase

  def setup
    @fetcher_class = Victoriassecret
    @sccs = SCCScraper.new(@fetcher_class)
    @item = Item.new
    @item.dept = :womens
    @item.clothing_type = {:group => :bottom, :bm => 3}
    @sccs.matchers({})
  end

  def test_calling_matchers_should_define_new_size_mapper
    @sccs = SCCScraper.new(@fetcher_class)
    @sccs.matchers({})
    assert_not_nil @sccs.instance_variable_get('@matchers')
  end

  def test_map_size_uses_extractors_before_size_mapping
    @sccs.extractors(/(\d+) US/)
    @sccs.matchers({
      "4 US" => "not mapped",
      "4" => "mapped"
    })
    Size.expects(:get_size).with(@fetcher_class,"mapped", @item).returns(["found"])
    assert_equal ["found"], @sccs.send(:map_size,"4 US", @item)
  end

  def test_map_sizes_should_use_size_mappers
    @sccs.matchers({
      "4 US" => "5",
    })
    Size.expects(:get_size).with(@fetcher_class,"5", @item).returns(["found"])
    assert_equal ["found"], @sccs.send(:map_size,"4 US", @item)
  end

  def test_map_sizes_should_use_extractor
    @sccs.extractors(/(\d+) US/)
    Size.expects(:get_size).with(@fetcher_class,"4", @item).returns(["found"])
    assert_equal ["found"], @sccs.send(:map_size,"4 US", @item)
  end

  def test_map_sizes_should_log_size_exceptions
    Size.expects(:get_size).with(@fetcher_class,"4", @item).raises(Size::SizeException)
    @fetcher_class.log.expects(:info)
    assert_equal [], @sccs.send(:map_size,"4", @item)
  end

  def test_extended_description_data_sets_field_appropriately_when_flag_is_true
    SCCScraper.grab_extended_description = true
    assert_nil @sccs.extended_description_definition
    @sccs.extended_description_data do
      puts "here"
    end
    assert @sccs.extended_description_definition
  end

  def test_extended_description_data_does_not_set_field_when_flag_is_false
    SCCScraper.grab_extended_description = false
    assert_nil @sccs.extended_description_definition
    @sccs.extended_description_data do
      puts "here"
    end
    assert_nil @sccs.extended_description_definition
  end

  def test_additional_images_sets_field_appropriately_when_flag_is_true
    SCCScraper.grab_additional_images = true
    assert_nil @sccs.additional_images_definition
    @sccs.additional_images do
      puts "here"
    end
    assert @sccs.additional_images_definition
  end

  def test_additional_images_does_not_set_field_when_flag_is_false
    SCCScraper.grab_additional_images = false
    assert_nil @sccs.additional_images_definition
    @sccs.additional_images do
      puts "here"
    end
    assert_nil @sccs.additional_images_definition
  end

  def test_additional_images_stores_returned_value
    SCCScraper.grab_additional_images = true
    @sccs.agent = mock(){expects(:page).returns(nil)}
    expected = {:something => "something"}
    @sccs.additional_images_definition = mock() do
      expects(:call).returns(expected)
    end
    item = mock() do
      expects(:additional_images=).with(expected)
      expects(:additional_images).returns({})
    end
    @sccs.handle_additional_images!(item)
  end

  def test_related_vendor_keys_sets_field_appropriately_when_flag_is_true
    SCCScraper.grab_related_vendor_keys = true
    assert_nil @sccs.related_vendor_keys_definition
    @sccs.related_vendor_keys do
      puts "here"
    end
    assert @sccs.related_vendor_keys_definition
  end

  def test_related_vendor_keys_does_not_set_field_when_flag_is_false
    SCCScraper.grab_related_vendor_keys = false
    assert_nil @sccs.related_vendor_keys_definition
    @sccs.related_vendor_keys do
      puts "here"
    end
    assert_nil @sccs.related_vendor_keys_definition
  end

  def test_related_vendor_keys_stores_uniq_flattened_no_nils
    Fetcher.stubs(:items_definition).returns(Proc.new(){})
    SCCScraper.grab_related_vendor_keys = true
    @sccs.agent = mock(){expects(:page).returns(nil)}
    @sccs.related_vendor_keys_definition = mock() do
      expects(:call).returns(["a",["b"],["a"],nil,nil])
    end
    expected = ["a","b"]
    item = mock() do
      expects(:related_vendor_keys=).with(expected)
    end
    @sccs.handle_related_vendor_keys!(item)
  end
  
end