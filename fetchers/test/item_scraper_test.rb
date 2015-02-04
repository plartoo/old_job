require File.dirname(__FILE__) + '/test_helper'
require 'thread_safe_counter'
class ItemScraperTest < Test::Unit::TestCase

  def setup
    @item_scraper = ItemScraper.new(Victoriassecret) {}
    @item = Item.new
    Brand.stubs(:get_best_matching_brand_bm).returns(0)
    @item_sccs_queue = FetcherWorkQueue.new
  end

  def test_category_clothing_type_overrides_item_clothing_type
    cat = Category.new('cat', 'example', false, :OUTERWEAR, :womens)
    ClothingTypeMatcher.stubs(:determine_clothing_type).returns(ClothingType[:JEANS, :womens])
    @item_scraper.send(:handle_item!, @item, cat)
    assert @item.clothing_type == ClothingType[:OUTERWEAR, :womens]
  end

  def test_should_not_override_item_clothing_type_if_cat_clothing_type_is_nil
    cat = Category.new('cat', 'example', false, nil, :womens)
    ClothingTypeMatcher.stubs(:determine_clothing_type).returns(ClothingType[:JEANS, :womens])
    @item_scraper.send(:handle_item!, @item, cat)
    assert @item.clothing_type == ClothingType[:JEANS, :womens]
  end

  def test_should_use_cat_clothing_type_if_clothing_type_matcher_returns_nil
    cat = Category.new('cat', 'example', false, :OUTERWEAR, :womens)
    ClothingTypeMatcher.stubs(:determine_clothing_type).returns(nil)
    @item_scraper.send(:handle_item!, @item, cat)
    assert @item.clothing_type == ClothingType[:OUTERWEAR, :womens]
  end

  def test_item_should_not_be_valid_if_clothing_type_matcher_and_cat_clothing_type_return_nil
    cat = Category.new('cat', 'example', false, nil, :womens)
    ClothingTypeMatcher.stubs(:determine_clothing_type).returns(nil)
    @item_scraper.send(:handle_item!, @item, cat)
    assert !@item.valid?
  end

  def setup_items
    @items = ItemScraper.new(Victoriassecret,{}) do
      item_block :selector => "/html/body/table/tr/td"
      vendor_key /(\d+)$/
      testing
      description {
        is "span"
        with_name "product"
      }
      product_url {
        is "a"
        with_href_like /null\.html/
      }
      product_image {
        is "img"
        with_src_like /null\.png/
        default_width 100
        default_height 100
      }
      original_price {
        is "span"
        with_id "oprice"
      }
      sale_price {
        is "span"
        with_id "sprice"
      }
    end
  end

  def test_general_scrape
    setup_items.scrape({:cat => Category.new("", "/item_page.html", "", nil, :womens),:item_sccs_queue => @item_sccs_queue,
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => ThreadSafeCounter.new,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
    items = []
    items << @item_sccs_queue.pop[:work] while @item_sccs_queue.size > 0

    assert_equal(8, items.size, "number of items")
    item_descriptions = items.map {|item| item.description}
    (1..8).to_a.each do |n|
      assert_equal true, item_descriptions.include?("jacket #{n}")
    end
  end

  def test_modify_item_parse_agent_during_item_scraping
    items = ItemScraper.new(Victoriassecret,{}) do
      modify_item_parse_agent do |agent, url|
        new_agent = Mechanize.new
        agent.page = new_agent.get(complete_href("/item_page_replacement.html"))
        agent
      end

      item_block "/html/body/table/tr/td"
      vendor_key /(.*)/
      testing

      description_custom do |root|
        nodes = root.search('.//span[@name="product"]')
        if nodes.nil?
          retnode = nodes
        else
          retnode = nodes[0]
        end
        retnode
      end

      product_url do
        is "a"
        with_href_like /null\.html/
      end

      product_image do
        is "img"
        with_src_like /null\.png/
        default_width 100
        default_height 100
      end

      original_price do
        is "span"
        with_id "oprice"
      end

      sale_price do
        is "span"
        with_id "sprice"
      end
    end    
    
    items.scrape({:cat => Category.new("", "/item_page.html", "", nil, :womens),:item_sccs_queue => @item_sccs_queue,
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => ThreadSafeCounter.new,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
    items = []
    items << @item_sccs_queue.pop[:work] while @item_sccs_queue.size > 0
    assert_equal(16, items.size, "number of items")
  end



  def test_custom_scrape
    items = ItemScraper.new(Victoriassecret,{}) do
      item_block "/html/body/table/tr/td"
      vendor_key /(.*)/
      testing

      description_custom do |root|
        nodes = root.search('.//span[@name="product"]')
        if nodes.nil?
          retnode = nodes
        else
          retnode = nodes[0]
        end
        retnode
      end

      product_url do
        is "a"
        with_href_like /null\.html/
      end

      product_image do
        is "img"
        with_src_like /null\.png/
        default_width 100
        default_height 100
      end

      original_price do
        is "span"
        with_id "oprice"
      end

      sale_price do
        is "span"
        with_id "sprice"
      end
    end
    items.scrape({:cat => Category.new("", "/item_page.html", "", nil, :womens),:item_sccs_queue => @item_sccs_queue,
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => ThreadSafeCounter.new,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
    items = []
    items << @item_sccs_queue.pop[:work] while @item_sccs_queue.size > 0

    assert_equal(8, items.size, "number of items")
  end

  def test_detail_page_scrape
    items = ItemScraper.new(Victoriassecret,{:from_detail_page => true}) do
      item_block :selector => "/html/body/table/tr/td"
      vendor_key /(.*)/
      testing
      description do
        is "span"
        with_name "product"
      end
      product_url do
        is "a"
      end
      product_image do
        is "img"
        with_src_like /null\.png/
        default_width 100
        default_height 100
      end
      original_price :from_detail_page => true do
        is "span"
        with_id "oprice"
      end
      sale_price do
        is "span"
        with_id "sprice"
      end
    end

    items.scrape({:cat => Category.new("", "/item_page_for_detail_page_scrape.html", "", nil, :womens),
        :item_sccs_queue => @item_sccs_queue,
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => ThreadSafeCounter.new,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
    items = []
    items << @item_sccs_queue.pop[:work] while @item_sccs_queue.size > 0
    assert_equal(2, items.size)

    item = items.first

    assert_equal("11.99", item.sale_price, "sale price from index page")
    assert_equal("20.00", item.original_price, "original price from detail page")
  end

  def test_detail_page_scrape_with_selectors
    items = ItemScraper.new(Victoriassecret,{:from_detail_page => true}) do
      item_block :selector => "/html/body/table/tr/td"
      vendor_key /(.*)/
      testing
      description :selector => 'span[name=product]'
      product_url :selector => 'a'
      product_image do
        is "img"
        with_src_like /null\.png/
        default_width 100
        default_height 100
      end
      original_price :from_detail_page => true, :selector => 'span#oprice'
      sale_price :selector => 'span#sprice'
    end

    items.scrape({:cat => Category.new("", "/item_page_for_detail_page_scrape.html", "", nil, :womens),
        :item_sccs_queue => @item_sccs_queue,
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => ThreadSafeCounter.new,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
    items = []
    items << @item_sccs_queue.pop[:work] while @item_sccs_queue.size > 0

    assert_equal(2, items.size)

    item = items.first

    assert_equal("11.99", item.sale_price, "sale price from index page")
    assert_equal("20.00", item.original_price, "original price from detail page")
  end

  def test_items_with_define_custom_item_list_sets_condition
    items = ItemScraper.new(Victoriassecret) do
      define_custom_item_list do |page|
        ["1", "2", "3"]
      end
    end
    items.evaluate_definition
    assert_not_nil items.conditions
    assert_not_nil items.conditions["custom_item_list"]
  end

  def test_items_with_define_custom_item_list_iterator_sets_condition
    items = ItemScraper.new(Victoriassecret,{}) do
      define_custom_item_list do |page|
        ["1", "2", "3"]
      end
      define_custom_item_list_iterator do |item, item_data|
        
      end
    end
    items.evaluate_definition
    assert_not_nil items.conditions["custom_item_list"].item_enumerator_block
  end
  
  def test_handle_item_should_respect_existing_brand_bm
    item_scraper = ItemScraper.new(Victoriassecret,{}, &Victoriassecret.items_definition)
    item = Item.new
    item.brand_bm = 34
    item.description = "G-Star pants"
    item_scraper.send(:handle_item!,item, Category.new("", "url", "", nil, :womens))
    assert_equal 34, item.brand_bm
  end

  %w(description original_price sale_price product_url brand notice).each do |part|
    [part, "#{part}_custom"].each do |part_name|
      define_method("test_#{part_name}_calls_add_part_with_correct_params") do
        item_scraper = ItemScraper.new(Victoriassecret,{}, &Victoriassecret.items_definition)
        item_scraper.expects(:add_part).with(part_name.to_sym, {})
        item_scraper.send(part_name, {})
      end
    end
  end

  def test_product_image_custom_calls_add_part_with_correct_params
    item_scraper = ItemScraper.new(Victoriassecret,{}, &Victoriassecret.items_definition)
    item_scraper.expects(:add_part).with(:product_image_custom, {:direct_value => true})
    item_scraper.send(:product_image_custom, {:direct_value => true})
  end

  def test_product_image_custom_raises_nothing
    assert_nothing_raised do
      items = ItemScraper.new(Victoriassecret,{:from_detail_page => true}) do
        item_block :selector => "/html/body/table/tr/td"
        vendor_key /(.*)/
        testing
        product_image_custom do |item_node|
          image = ItemImage.new('image.png')
          image.height = 135
          image.width = 135
        end
      end
      items.scrape({:cat => Category.new("", "/item_page_for_detail_page_scrape.html"),
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => ThreadSafeCounter.new,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
    end
  end

  def test_scraping_full_price_items_if_full_price_items_variable_is_passed_in_as_option
    items = ItemScraper.new(Victoriassecret,{}) do
      item_block "/html/body/table/tr/td"
      vendor_key /(.*)/
      testing

      description_custom do |root|
        nodes = root.search('.//span[@name="product"]')
        if nodes.nil?
          retnode = nodes
        else
          retnode = nodes[0]
        end
        retnode
      end

      product_url do
        is "a"
        with_href_like /null\.html/
      end

      product_image do
        is "img"
        with_src_like /null\.png/
        default_width 100
        default_height 100
      end

      original_price do
        is "span"
        with_id "oprice"
      end

      sale_price do
        is "span"
        with_id "sprice"
      end
    end
    items.scrape({:cat => Category.new("", "/item_page.html", "", nil, :womens),:item_sccs_queue => @item_sccs_queue,
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => ThreadSafeCounter.new,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new,
      :full_price_items => true,
    })
    items = []
    items << @item_sccs_queue.pop[:work] while @item_sccs_queue.size > 0

    assert_equal(9, items.size, "number of items")
  end

  def test_save_category_data_does_nothing_if_flag_not_set_to_true
    @item_scraper.add_category_info_to_item = false
    @item_scraper.past_items_cat_data = ThreadSafeHash.new
    @item_scraper.save_category_data!("some key","some category")
    assert_equal ThreadSafeHash.new, ItemScraper.past_items_cat_data
  end

  def test_save_category_data_stores_new_hash_in_array
    @item_scraper.add_category_info_to_item = true
    ItemScraper.past_items_cat_data = ThreadSafeHash.new
    url = "url"
    name = "name"
    category_path = "category_path"
    cat = mock() do
      expects(:url).returns(url)
      expects(:name).returns(name)
      expects(:category_path).returns(category_path)
    end
    key = "some key"
    @item_scraper.save_category_data!(key,cat)
    assert_equal ({key => [{:url => url, :name => name, :path => category_path}]}),
      @item_scraper.past_items_cat_data.data
  end

  def test_add_category_data_to_item_doesnt_do_anything_if_flag_is_false
    @item_scraper.add_category_info_to_item = false
    ItemScraper.past_items_cat_data = ThreadSafeHash.new
    @item_scraper.add_category_data_to_item!("some item")
    assert_equal ThreadSafeHash.new, @item_scraper.past_items_cat_data
  end

  def test_add_category_data_to_item_sets_hash_key_value_to_stored_value_if_flag_is_true
    @item_scraper.add_category_info_to_item = true
    ItemScraper.past_items_cat_data = ThreadSafeHash.new
    vendor_key = "vendor_key"
    value = "value"
    ItemScraper.past_items_cat_data[vendor_key] = value
    item = mock() do
      expects(:vendor_key).returns(vendor_key)
      expects(:category_data=).with(value)
    end

    @item_scraper.add_category_data_to_item!(item)
  end

  def test_add_category_data_to_item_sets_hash_key_value_to_empty_array_if_flag_is_true_and_no_value_set
    @item_scraper.add_category_info_to_item = true
    ItemScraper.past_items_cat_data = ThreadSafeHash.new
    vendor_key = "vendor_key"
    ItemScraper.past_items_cat_data[vendor_key] = nil
    item = mock() do
      expects(:vendor_key).returns(vendor_key)
      expects(:category_data=).with([])
    end

    @item_scraper.add_category_data_to_item!(item)
  end

  def test_handle_item_uses_cat_brand_if_brand_and_item_brand_are_nil
    expected_brand = "some brand"
    expected_brand_bm = 123
    dept = "dept"
    Brand.stubs(:get_best_matching_brand_bm).with(dept,expected_brand).returns(expected_brand_bm)
    item = mock() do
      expects(:dept).returns(dept).at_least_once
      expects(:vendor_name=).at_least_once
      expects(:clothing_type).returns(:OUTERWEAR).at_least_once
      expects(:clothing_type=).returns(nil).at_least_once
      expects(:brand).returns(nil).at_least_once
      expects(:brand_bm).returns(nil).at_least_once
      expects(:brand_bm=).with(expected_brand_bm).at_least_once
      expects(:currency).returns("us")
    end
    cat = mock() do
      expects(:brand).returns(expected_brand).at_least_once
      expects(:clothing_type).returns(:OUTERWEAR).at_least_once
    end
    @item_scraper.send(:handle_item!,item,cat)
  end

end
