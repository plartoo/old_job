require File.dirname(__FILE__) + '/test_helper'

class FetcherThreadPoolTest < Test::Unit::TestCase

  def setup
    @num_threads = 3
    @time_to_stop = 5
    @config = {:num_threads => @num_threads, :time_to_stop => @time_to_stop}
    @pool = FetcherThreadPool.new(@config)
  end

  def test_initialize_sets_variables_correctly
    assert_equal @config, @pool.configuration
    assert_equal [], @pool.threads
  end

  def test_size_is_zero_on_new_pool
    assert_equal 0, @pool.size
  end
  
  def test_run_raises_error_since_no_submethod_defined
    assert_raise FetcherThreadPool::NoSpawnThreadMethodDefined do
      @pool.run
    end
  end

  def test_fetcher_has_time_left_returns_true_if_no_stop_time_defined
    @pool.configuration[:time_to_stop] = nil
    assert @pool.fetcher_has_time_left?
  end

  def test_fetcher_has_time_left_returns_true_if_stop_time_is_bigger_than_time_now
    @pool.configuration[:time_to_stop] = 5
    assert @pool.fetcher_has_time_left?(4)
  end

  def test_fetcher_has_time_left_returns_true_if_stop_time_is_smaller_than_time_now
    @pool.configuration[:time_to_stop] = 4
    assert !@pool.fetcher_has_time_left?(5)
  end

end
