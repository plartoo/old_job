require File.dirname(__FILE__) + '/test_helper'

class FetcherTest < Test::Unit::TestCase

  class TestSetupAgentFetcher
    extend Fetcher
    setup do |agent|
      agent.user_agent = "set"
    end
  end

  def setup
    @fetcher_name = 'victoriassecret'
    @fetcher_class_name = 'Victoriassecret'
    @fetcher_class = Victoriassecret
    @fetcher = FetcherHelperMethods.spawn_new_fetcher_instance(@fetcher_class_name,@fetcher_name)
  end
  
  def test_setup_sets_user_agent_properties_correctly
    agent = FetcherHelperMethods.agent(@fetcher_class)
    TestSetupAgentFetcher::setup_block.call(agent)
    assert_equal "set", agent.user_agent
  end

  def test_fetcher_agent_returns_unique_agent_objects
    assert FetcherHelperMethods.agent(@fetcher_class) != FetcherHelperMethods.agent(@fetcher_class)
  end

  def test_should_set_vendor_path_from_vendor_name
    assert_equal ['ClassName', 'class_name'], FetcherHelperMethods.class_and_name('ClassName')
  end

  def test_should_not_override_vendor_path_if_provided
    assert_equal ['ClassName', 'classname'], FetcherHelperMethods.class_and_name('ClassName', 'classname')
  end

  def test_setting_i18n_version_should_set_i18n_version_and_application
    @fetcher_class.i18n_version = 'us'
    assert_equal 'us', @fetcher_class.i18n_version
    assert_equal 'us', Configuration.application
  end

  def test_get_categories_should_look_for_i18n_version
    @fetcher_class.i18n_version = 'us'
    cat_path = File.join(FetcherHelperMethods.dir_path(@fetcher_name), "#{@fetcher_name}_categories.us.yml")
    @fetcher_class.expects(:populate_category_file_paths).with([nil]).returns([cat_path])
    File.stubs(:exist?).returns(true)
    CategoryGenerator.expects(:load_yaml_from_file).with([cat_path])
    @fetcher.get_categories
  end

  def test_get_categories_should_look_for_default_if_i18n_version_not_found
    cat_path = File.join(FetcherHelperMethods.dir_path(@fetcher_name), "#{@fetcher_name}_categories.yml")
    @fetcher_class.expects(:populate_category_file_paths).with([nil]).returns([cat_path])
    File.stubs(:exist?).returns(true)
    CategoryGenerator.expects(:load_yaml_from_file).with([cat_path])
    @fetcher.get_categories
  end

  def setup_sccs_scrape_testing
    @fetcher.scc_scraper = mock
    @agent = mock
    @log = mock
    @log.stubs(:info)
    @log.stubs(:error)
    @log.stubs(:debug)
    @agent.stubs(:back!)
    @fetcher_class.log = @log
    @fetcher.scc_scraper.stubs(:scrape)
    @fetcher.scc_scraper.stubs(:agent).returns(@agent)
    @sccs = [{:size_bm=>12, :size_type_bm=>0, :color=>"Mono"},
      {:size_bm=>13, :size_type_bm=>0, :color=>"Mono"},
      {:size_bm=>14, :size_type_bm=>0, :color=>"Mono"},
      {:size_bm=>17, :size_type_bm=>0, :color=>"Mono"}]

  end

  def setup_sccs_item_collection
    @items = []
    some_dummy_variable = "1"
    5.times do |i|
      #set product_url to i so each item is unique when compared by ==
      item = Item.new(:product_url => i)
      item.clothing_type_bm = some_dummy_variable
      item.scc = []
      item.brand_bm = some_dummy_variable
      item.vendor_key = some_dummy_variable
      item.description = some_dummy_variable
      item.product_url = some_dummy_variable
      item.product_image = ItemImage.new(some_dummy_variable,some_dummy_variable,some_dummy_variable,some_dummy_variable)
      item.original_price = "2"
      item.sale_price = some_dummy_variable

      @items << item
    end
  end

  def test_is_valid_item_returns_true_when_item_has_correct_data
    item = mock 'item' do
      expects(:scc).returns(['something']).twice
      expects(:valid?).returns(true)
      expects(:on_sale?).returns(true)
    end
    @fetcher.stubs(:is_forbidden_brand_item?).returns(false)
    assert @fetcher.is_valid_item?(item)
  end

  def test_is_valid_item_returns_false_when_not_valid_item
    item = mock 'item' do
      expects(:scc).returns(['something']).twice
      expects(:valid?).returns(false)
    end
    @fetcher.stubs(:is_forbidden_brand_item?).returns(false)
    assert !@fetcher.is_valid_item?(item)
  end

  def test_is_valid_item_returns_false_when_not_on_sale
    item = mock 'item' do
      expects(:scc).returns(['something']).twice
      expects(:valid?).returns(true)
      expects(:on_sale?).returns(false)
    end
    @fetcher.stubs(:is_forbidden_brand_item?).returns(false)
    assert !@fetcher.is_valid_item?(item)
  end

  def test_is_valid_item_returns_false_when_nil_scc_data
    item = mock(:scc => nil)
    @fetcher.stubs(:is_forbidden_brand_item?).returns(false)
    assert !@fetcher.is_valid_item?(item)
  end

  def test_is_valid_item_returns_false_when_no_scc_data
    item = mock 'item' do
      expects(:scc).returns([]).twice
    end
    @fetcher.stubs(:is_forbidden_brand_item?).returns(false)
    assert !@fetcher.is_valid_item?(item)
  end

  def test_scrape_sccs_calls_scc_scraper_scrape_with_provided_options
    setup_sccs_scrape_testing
    options = {:item => Item.new,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new}
    @fetcher.scc_scraper.stubs(:scrape).with(options)
    @agent.expects(:back!)
    @fetcher.stubs(:is_forbidden_brand_item?).returns(false)
    @fetcher.scrape_sccs(options)
  end
  
  def test_scrape_sccs_calls_scc_scraper_for_each_item_in_provided_collection
    setup_sccs_scrape_testing
    setup_sccs_item_collection
    @items.each do |item|
      @scc_scraper.stubs(:scrape).with({:item => item})
    end
    @fetcher.stubs(:is_forbidden_brand_item?).returns(false)
    @fetcher.scrape_sccs({:item => @items.first, :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
  end
  
  def test_scrape_sccs_respects_provided_item_limit
    setup_sccs_scrape_testing
    setup_sccs_item_collection
    @fetcher_class.log.stubs(:info).returns(nil)

    @fetcher.scc_scraper.stubs(:scrape).with({:item => @items.first,
        :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
    
    assert_nothing_raised do
      @fetcher.stubs(:is_forbidden_brand_item?).returns(false)
      @fetcher.scrape_sccs(:item => @items.first, :item_limit => 3,
        :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new)
    end
  end
  
  def test_scrape_sccs_ignores_item_limit_when_item_limit_is_nil
    setup_sccs_scrape_testing
    setup_sccs_item_collection
    expected_passed = []
    expected_failed = []

    @fetcher.scc_scraper.stubs(:scrape).with({:item => @items.first}).returns(@sccs)
    expected_passed << @items.first

    failed = ThreadSafeCounter.new
    passed = ThreadSafeCounter.new
    @fetcher.stubs(:is_forbidden_brand_item?).returns(false)
    @fetcher.scrape_sccs(:item => @items.first, :item_limit => nil,:output_queue => FetcherWorkQueue.new, :failed_item_counter => failed, :processed_item_counter => passed)
    assert_equal expected_passed.length, passed.value
  end
  
  def test_scrape_sccs_single_item_sets_scc_to_item
    setup_sccs_scrape_testing
    item = Item.new
    sccs = [{:size_bm=>12, :size_type_bm=>0, :color=>"Mono"},
      {:size_bm=>13, :size_type_bm=>0, :color=>"Mono"},
      {:size_bm=>14, :size_type_bm=>0, :color=>"Mono"},
      {:size_bm=>17, :size_type_bm=>0, :color=>"Mono"}]
    @fetcher.scc_scraper.expects(:scrape).with({:item => item}).returns(sccs)
    @fetcher.sccs_scrape_single_item({:item => item})
    assert_equal sccs, item.scc
  end
  
  def test_scrape_sccs_single_item_sets_scc_to_item_raises_exception_and_log
    setup_sccs_scrape_testing
    item = Item.new
    @fetcher.scc_scraper.expects(:scrape).with({:item => item}).raises("SCC error raised")
    assert_nothing_raised do
      @fetcher.sccs_scrape_single_item({:item => item,
          :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => ThreadSafeCounter.new})
    end
    assert_equal nil, item.scc
  end
  
  def test_scrape_sccs_splits_processed_and_failed_items
    setup_sccs_scrape_testing
    setup_sccs_item_collection
    expected_passed = []
    expected_failed = []

    @fetcher.scc_scraper.stubs(:scrape).with({:item => @items.first}).returns(@sccs)
    expected_passed << @items.first

    failed = ThreadSafeCounter.new
    passed = ThreadSafeCounter.new
    @fetcher.stubs(:is_forbidden_brand_item?).returns(false)
    @fetcher.scrape_sccs(:item => @items.first,:output_queue => FetcherWorkQueue.new,
      :failed_item_counter => failed, :processed_item_counter => passed)
    assert_equal expected_passed.length, passed.value
  end

  def test_scrape_sccs_respects_provided_time_limit
    setup_sccs_scrape_testing
    setup_sccs_item_collection
    def (@fetcher.scc_scraper).scrape(options)
      sleep 5
      [{:size_bm=>12, :size_type_bm=>0, :color=>"Mono"}]
    end

    passed = ThreadSafeCounter.new
    @fetcher.stubs(:is_forbidden_brand_item?).returns(false)
    @fetcher.scrape_sccs(:item => @items.first,:output_queue => FetcherWorkQueue.new, :time_limit_in_mins => 0.05,
      :time_started => Time.now.to_i,
      :failed_item_counter => ThreadSafeCounter.new, :processed_item_counter => passed)

    assert_equal 1, passed.value
  end
  
  def test_create_logger_sets_fetcher_log
    # store previous logger, keep as transaction
    temp_logger = @fetcher_class.log
    @fetcher_class.log = nil
    assert_nil @fetcher_class.log
    test_log_file = Tempfile.new("fetcher_test_log")
    @fetcher_class.create_logger(*File.split(test_log_file.path))
    assert_not_nil @fetcher_class.log
    @fetcher_class.log = temp_logger
  end

  def test_spawn_new_fetcher_instance_returns_new_fetcher_instances
    FetcherHelperMethods.expects(:load_fetcher_file).twice
    first = FetcherHelperMethods.spawn_new_fetcher_instance(@fetcher_class_name,@fetcher_name)
    second = FetcherHelperMethods.spawn_new_fetcher_instance(@fetcher_class_name, @fetcher_name)
    assert first != second, "Fetcher instances should be unique"
  end

  def test_apply_coupons_correctly_applies_coupons_when_applicable
    item = mock('item') do
      expects(:valid_full_price?).returns(true)
    end

    coupon = mock('coupon') do
      expects(:applies_to?).returns(true)
      expects(:new_price_would_be)
      expects(:apply_discount!)
    end

    @fetcher.apply_coupons(item,[coupon])
  end

  def teardown
    mocha_teardown
    @fetcher_class.send(:class_variable_set,"@@scc_scraper",@scc_scraper)
  end

  def test_is_valid_item_calls_forbidden_brand_item
    item = mock('item') do
      expects(:scc).returns(['something']).twice
      expects(:valid?).returns(true)
      expects(:on_sale?).returns(true)
    end

    @fetcher.expects(:is_forbidden_brand_item?)
    @fetcher.is_valid_item?(item)
  end

  def test_is_valid_item_calls_is_forbidden_brand_item
    item = mock('item') do
      expects(:scc).returns(['something']).twice
      expects(:valid?).returns(true)
      expects(:on_sale?).returns(true)
    end

    @fetcher.expects(:is_forbidden_brand_item?)
    @fetcher.is_valid_item?(item)
  end

  def test_is_forbidden_brand_item_returns_false_if_forbidden_brand_list_is_empty_or_nonexistent
    item = mock('item') do
      expects(:dept).returns(:womens)
      expects(:brand_bm).returns(1)
    end

    options = {}
    assert_equal false, @fetcher.is_forbidden_brand_item?(item,options)
  end

  def test_is_forbidden_brand_item_returns_true_if_forbidden_brand_list_is_includes_matching_brand_bm
    item = mock('item') do
      expects(:dept).returns(:womens)
      expects(:brand_bm).returns(1)
    end

    options = {:forbidden_brands=>{:womens=>[1,2,3],:mens=>[],:girls=>[],:boys=>[]}}

    assert_equal true, @fetcher.is_forbidden_brand_item?(item,options)
  end

  def test_is_forbidden_brand_item_returns_false_if_forbidden_brand_list_is_does_not_includes_matching_brand_bm
    item = mock('item') do
      expects(:dept).returns(:womens)
      expects(:brand_bm).returns(5)
    end

    options = {:forbidden_brands=>{:womens=>[1,2,3],:mens=>[],:girls=>[],:boys=>[]}}

    assert_equal false, @fetcher.is_forbidden_brand_item?(item,options)
  end

  def test_data_sender_short_name_returns_shorter_name_correctly_on_short_name
    temp_name = @fetcher_class.fetcher_name

    @fetcher_class.fetcher_name = "short"
    assert_equal "short", @fetcher_class.data_sender_short_name

    @fetcher_class.fetcher_name = temp_name
  end

  def test_data_sender_short_name_returns_shorter_name_correctly_on_long_name
    temp_name = @fetcher_class.fetcher_name

    @fetcher_class.fetcher_name = "some_long_name"
    assert_equal "some_long_", @fetcher_class.data_sender_short_name

    @fetcher_class.fetcher_name = temp_name
  end

  def test_data_sender_short_name_returns_empty_string_on_empty_name
    temp_name = @fetcher_class.fetcher_name

    @fetcher_class.fetcher_name = ""
    assert_equal "", @fetcher_class.data_sender_short_name

    @fetcher_class.fetcher_name = temp_name
  end

end
