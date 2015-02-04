require File.dirname(__FILE__) + '/test_helper'
require 'index_scraper_thread_pool'

class IndexScraperThreadPoolTest < Test::Unit::TestCase

  def setup
    @num_threads = 3
    @time_to_stop = 5
    @input_queue = FetcherWorkQueue.new
    @output_queue = FetcherWorkQueue.new
    @fetcher_class = Victoriassecret
    @config = {:num_threads => @num_threads, :fetcher_class => @fetcher_class, :time_to_stop => @time_to_stop, :index_work_queue => @input_queue,
                :item_sccs_queue => @output_queue}
    @pool = IndexScraperThreadPool.new(@config)
  end

  def test_initialize_sets_variables_correctly_by_calling_super
    assert_equal @config, @pool.configuration
    assert_equal [], @pool.threads
    assert_equal @input_queue, @pool.input_queue
    assert_equal @output_queue, @pool.output_queue
    assert_equal Queue, @pool.finished_threads.class
  end

  def test_join_calls_shutdown_when_timed_out
    @pool.stubs(:fetcher_has_time_left?).returns(true)
    @pool.stubs(:all_threads_finished?).returns(true)
    num = 5
    num.times {@input_queue << "something"}
    assert_equal num,@input_queue.size
    @pool.threads << Thread.new{ puts "running" }
    @pool.join
    assert @input_queue.shutdown?
  end

  def test_spawn_and_return_thread_returns_thread
    Thread.stubs(:new).returns("ran")
    assert_equal "ran", @pool.spawn_and_return_thread
  end

  def test_all_threads_finished_returns_true_when_all_finished
    threads = []
    @num_threads.times do
      threads << Thread.new(@pool.finished_threads) do |finished|
        sleep(2)
        finished << IndexScraperThreadPool::ALL_DONE
      end
    end
    threads.each {|thr| thr.join}
    assert @pool.all_threads_finished?
  end

  def test_scrape_items_from_cat_returns_number_scraped_and_doesnt_push_scraper
    num_items = 4
    item_scraper = mock(:scrape => [num_items,nil])
    assert_equal num_items, @pool.scrape_items_from_cat("a url",item_scraper)
    assert_equal 0, @pool.input_queue.size
  end

  def test_scrape_items_from_cat_pushes_scraper_onto_queue_if_valid
    num_items = 4
    valid_category = "some valid category"
    item_scraper = mock(:scrape => [num_items,valid_category])
    assert_equal num_items, @pool.scrape_items_from_cat("a url",item_scraper)
    assert_equal ({:type=>IndexScraperThreadPool::CATEGORY_TO_SCRAPE, :work => valid_category}),
          @pool.input_queue.pop
  end

end
