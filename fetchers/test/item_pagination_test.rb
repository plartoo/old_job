require 'test_helper'

class ItemPaginationTest < Test::Unit::TestCase

  def setup
    @test_clothing_type = :OUTERWEAR
    @item_sccs_queue = FetcherWorkQueue.new
    @item_scraper = ItemScraper.new(Victoriassecret,{}) do
      testing
      vendor_key /(\d+)$/
      item_block "/html/body/table/tr/td"
      
      pagination do
        select do
          is "a"
          with_class "paginate"
        end
      end

      description do
        is "span"
        with_name "product"
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
  end

  def test_selected_pagination
    processed = ThreadSafeCounter.new
    @item_scraper.scrape({:cat => Category.new("", "/item_page_with_pagination_1.html", "", @test_clothing_type, :womens),
                  :item_sccs_queue => @item_sccs_queue,
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => processed,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
    items = []
    while @item_sccs_queue.size > 0
      items << @item_sccs_queue.pop[:work]
    end

    items.map!{|item| item.description}
    
    assert_equal(2, items.size, "item array size")
    (1..2).each do |n|
      assert_equal(true, items.include?('jacket ' + n.to_s), 'jacket ' + n.to_s)
    end
  end

  def test_selected_pagination_implied_origin
    processed = ThreadSafeCounter.new
    @item_scraper.scrape({:cat => Category.new("", "/item_page_with_pagination_implied_1.html", "", @test_clothing_type, :womens),
                  :item_sccs_queue => @item_sccs_queue,
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => processed,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})

    items = []
    while @item_sccs_queue.size > 0
      items << @item_sccs_queue.pop[:work]
    end
    items.map!{|item| item.description}

    assert_equal(2, items.size, "item array size")
    (1..2).each do |n|
      assert_equal(true, items.include?('jacket ' + n.to_s), 'jacket ' + n.to_s)
    end
  end

  def test_modifier_pagination
    scraper = ItemScraper.new(Victoriassecret,{}) do
      testing
      item_block "/html/body/table/tr/td"
      vendor_key /(.*)/

      pagination do
        url_pattern /(.*item_page_with_pagination_)\d(\.html)/
        increment_start 1
      end

      description do
        is "span"
        with_name "product"
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

    processed = ThreadSafeCounter.new
    scraper.scrape({:cat => Category.new("", "item_page_with_pagination_1.html", "", @test_clothing_type, :womens),
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => processed,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})

    assert_equal(2, processed.value, "item array size")
  end

  def test_modifier_pagination_with_empty_page
    scraper = ItemScraper.new(Victoriassecret,{}) do
      testing
      vendor_key /(.*)/
      item_block "/html/body/table/tr/td"

      pagination do
        url_pattern /(.*item_page_with_pagination_)\d(\.html)/
        increment_start 2
        increment_step 2
      end

      description do
        is "span"
        with_name "product"
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

    processed = ThreadSafeCounter.new
    scraper.scrape({:cat => Category.new("", "item_page_with_pagination_2.html", "", @test_clothing_type, :womens),
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => processed,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
    
    assert_equal(2, processed.value, "item array size")
  end

  def test_url_transformer
    scraper = ItemScraper.new(Victoriassecret,{}) do
      testing
      vendor_key /(\d+)/
      item_block "/html/body/table/tr/td"

      pagination do
        url_pattern /(.*item_page_with_pagination_)\d(\.html)/
        increment_start 2
        increment_step 2

        transformer do |url|
          url.sub(/pagination/, 'transformed')
        end
      end

      description do
        is "span"
        with_name "product"
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

    item_sccs_queue = FetcherWorkQueue.new
    processed = ThreadSafeCounter.new
    scraper.scrape({:cat => Category.new('', '/item_page_with_pagination_2.html', "", @test_clothing_type, :womens),
        :item_sccs_queue => item_sccs_queue,
      :item_scraper_total_counter => ThreadSafeCounter.new, :item_scraper_valid_counter => processed,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
    assert_equal(2, processed.value, "number of items")
    item = item_sccs_queue.pop[:work]
    assert_equal('10.00', item.original_price, "scrape off of correct page")
  end

end
