require 'test_helper'

require File.dirname(__FILE__)+"/../lib/singlethread_framework"

class SinglethreadFrameworkTest < Test::Unit::TestCase

  def setup
    @fetcher = Victoriassecret.new
    Victoriassecret.log = Logger.new(STDOUT)
    @config = {:fetcher => @fetcher, :fetcher_name => "victoriassecret", :i18n_version => 'us',
               :fetcher_class => Victoriassecret, :coupons => [], :options => {}, :log => Logger.new(STDOUT)}
    @framework = SinglethreadFramework.new(@config)
  end

  def test_scrape_items_from_categories_iterates_categories_the_right_number_of_times
    ItemScraper.stubs(:new).returns(nil)
    Fetcher.stubs(:items_options).returns({})
    active_cats = [1,2,3,4,5]
    cats = {:active => active_cats}
    @framework.cats_from_file = cats
    @framework.stubs(:do_category_and_get_items).returns([]).times(active_cats.size)
    assert_nothing_raised do
      @framework.scrape_items_from_categories
    end
  end

  def test_scrape_items_from_categories_concats_and_returns_results_from_do_cat_correctly
    ItemScraper.stubs(:new).returns(nil)
    Fetcher.stubs(:items_options).returns({})
    active_cats = [1,2,3,4,5]
    num = active_cats.size
    cats = {:active => active_cats}
    @framework.cats_from_file = cats
    items = ["something"]
    @framework.stubs(:do_category_and_get_items).returns(items).times(active_cats.size)
    result = @framework.scrape_items_from_categories
    expected = []
    num.times{ expected.concat(items)}
    assert_equal expected, result
  end

  def test_do_category_and_get_items_returns_result_from_items_from_category
    cat = mock(){expects(:name).returns("name"); expects(:paginator_iterations).returns(1)}
    expected = "something"
    @framework.stubs(:items_from_category).returns(expected)
    assert_equal expected, @framework.do_category_and_get_items(cat, "some item scraper", "some options")
  end

  def test_do_category_and_get_items_returns_empty_array_on_error
    @framework.stubs(:items_from_category).returns("something")
    assert_equal [], @framework.do_category_and_get_items("not a category", "some item scraper", "some options")
  end

  def test_items_from_category_returns_empty_array_on_scrape_without_error
    item_scraper = mock(){expects(:scrape).returns([nil,nil])}
    assert_equal [], @framework.items_from_category("cat",item_scraper,{})
  end

  def test_items_from_category_loads_cat_back_onto_queue_if_valid
    some_cat = "some valid category"
    item_scraper = mock(){expects(:scrape).returns([nil,some_cat])}
    @framework.cats_from_file = {:active => []}
    @framework.items_from_category("cat",item_scraper,{})
    assert_equal [some_cat], @framework.cats_from_file[:active]
  end

  def test_scrape_sccs_data_for_doesnt_call_scrape_sccs_if_time_over
    time_now = 2
    @framework.options = {:time_to_stop => 1}
    @framework.fetcher = mock(){expects(:scrape_sccs).times(0)}
    @framework.scrape_sccs_data_for(["some item"],time_now)
  end

end
