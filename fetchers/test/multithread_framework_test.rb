require 'test_helper'

require File.dirname(__FILE__)+"/../lib/multithread_framework"

class MultithreadFrameworkTest < Test::Unit::TestCase
  
  def setup
    @config = {:coupons => [], :i18n_version => 'us'}
    @framework = MultithreadFramework.new(@config)
  end

  def test_run_initializes_thread_pools
    @framework.stubs(:join_and_return_stats).returns(nil)
    @framework.stubs(:setup).returns(nil)
    IndexScraperThreadPool.stubs(:new).returns(mock(){expects(:run).returns(nil) })
    ItemSccsThreadPool.stubs(:new).returns(mock(){expects(:run).returns(nil) })
    OutputThreadPool.stubs(:new).returns(mock(){expects(:run).returns(nil) })

    @framework.config_data = {}
    @framework.run
    assert_not_nil @framework.index_thread_pool
    assert_not_nil @framework.item_sccs_thread_pool
    assert_not_nil @framework.output_thread_pool
  end

  def test_join_and_return_stats_calls_join_on_pools
    @framework.index_thread_pool = mock(){expects(:join).returns(nil) }
    @framework.item_sccs_thread_pool = mock(){expects(:join).returns(nil) }
    @framework.item_scraper_valid_counter = mock(){expects(:value).returns(1)}
    @framework.failed_item_counter = mock(){expects(:value).returns(1)}
    new_mock = mock(){expects(:value).returns(1)}
    @framework.output_thread_pool = mock(){expects(:join).returns(nil); expects(:output_counter).returns(new_mock);expects(:duplicate_output_counter).returns(ThreadSafeCounter.new); }

    @framework.stubs(:cleanup).returns(nil)
    assert_nothing_raised do
      @framework.join_and_return_stats
    end
  end

  def test_join_and_return_stats_returns_hash_with_at_least_these_three_keys
    @framework.index_thread_pool = mock(){expects(:join).returns(nil) }
    @framework.item_sccs_thread_pool = mock(){expects(:join).returns(nil) }

    successfully_scraped_count = "some number"
    new_mock = mock(){expects(:value).returns(successfully_scraped_count)}
    @framework.output_thread_pool = mock(){expects(:join).returns(nil); expects(:output_counter).returns(new_mock);expects(:duplicate_output_counter).returns(ThreadSafeCounter.new); }

    total_valid_count = "some other number"
    @framework.item_scraper_valid_counter = mock(){expects(:value).returns(total_valid_count)}

    failed_item_count = "some really low other number"
    @framework.failed_item_counter = mock(){expects(:value).returns(failed_item_count)}

    @framework.stubs(:cleanup).returns(nil)
    
    result = @framework.join_and_return_stats
    expected = {
      :successfully_scraped_count => successfully_scraped_count,
      :total_valid_count => total_valid_count,
      :duplicate_items_written_out => 0,
      :failed_item_count => failed_item_count,
    }
    assert_equal expected, result
  end


end
