require File.dirname(__FILE__) + '/test_helper'
require 'item_sccs_thread_pool'

class ItemSccsThreadPoolTest < Test::Unit::TestCase

  def setup
    @num_threads = 3
    @time_to_stop = 5
    @input_queue = FetcherWorkQueue.new
    @output_queue = FetcherWorkQueue.new
    @processed = Queue.new
    @failed = Queue.new
    @config = {:num_threads => @num_threads, :time_to_stop => @time_to_stop, :item_sccs_queue => @input_queue,
                :output_queue => @output_queue, :processed_sccs_items => @processed, :failed_sccs_items => @failed}
    @pool = ItemSccsThreadPool.new(@config)
  end

  def test_initialize_sets_variables_correctly_by_calling_super
    assert_equal @config, @pool.configuration
    assert_equal [], @pool.threads
    assert_equal @input_queue, @pool.input_queue
    assert_equal @output_queue, @pool.output_queue
  end

  def test_join_pushes_on_terminator_for_each_thread
    @pool.threads << Thread.new{ puts "running" }
    @pool.join
    assert_equal @num_threads, @input_queue.size
    @num_threads.times{
      assert_equal ItemSccsThreadPool::TERMINATE_WORK, @input_queue.pop[:type]
    }
  end

  def test_spawn_and_return_thread_returns_thread
    Thread.stubs(:new).returns("ran")
    assert_equal "ran", @pool.spawn_and_return_thread
  end

  def test_scrape_sccs_info
    fetcher = FetcherHelperMethods.spawn_new_fetcher_instance('Victoriassecret','victoriassecret')
    fetcher.expects(:scrape_sccs).returns(nil)
    @pool.scrape_sccs_info(fetcher,"some item")
  end
end
