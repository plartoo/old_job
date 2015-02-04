require File.dirname(__FILE__) + '/test_helper'
require 'full_priced_index_scraper_thread_pool'

class FullPricedIndexScraperThreadPoolTest < Test::Unit::TestCase

  def setup
    @num_threads = 3
    @time_to_stop = 5
    @input_queue = FetcherWorkQueue.new
    @output_queue = FetcherWorkQueue.new
    @fetcher_class = Victoriassecret
    @config = {:num_threads => @num_threads, :fetcher_class => @fetcher_class, :time_to_stop => @time_to_stop, :index_work_queue => @input_queue,
                :item_sccs_queue => @output_queue}
    @pool = FullPricedIndexScraperThreadPool.new(@config)
  end

  def test_create_item_scraper_returns_item_scraper_with_pagination_max_removed
    @fetcher_class.stubs(:items_options).returns({})
    @fetcher_class.stubs(:items_definition).returns(Proc.new(){ })
    scraper = @pool.create_item_scraper
    assert_nil scraper.paginator.stop
  end

end
