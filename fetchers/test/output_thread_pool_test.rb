require File.dirname(__FILE__) + '/test_helper'
require 'output_thread_pool'

class OutputThreadPoolTest < Test::Unit::TestCase

  def setup
    @num_threads = 3
    @time_to_stop = 5
    @queue = FetcherWorkQueue.new
    @config = {:num_threads => @num_threads, :time_to_stop => @time_to_stop, :output_queue => @queue}
    @pool = OutputThreadPool.new(@config)
  end

  def test_initialize_sets_variables_correctly_by_calling_super
    assert_equal @config, @pool.configuration
    assert_equal [], @pool.threads
    assert_equal @queue, @pool.input_queue
  end

  def test_join_pushes_on_terminator
    assert_equal 0,@queue.size
    @pool.threads << Thread.new{ puts "running" }
    @pool.join
    assert_equal 1, @queue.size
    assert_equal OutputThreadPool::TERMINATE_WORK, @queue.pop
  end

  def test_spawn_and_return_thread_returns_thread
    Thread.stubs(:new).returns("ran")
    @pool.stubs(:create_output_stream).returns(nil)
    assert_equal "ran", @pool.spawn_and_return_thread
  end

  def test_create_output_stream_returns_test_stream
    assert_equal "something", @pool.create_output_stream("something")
  end

  def test_grab_num_from_queue_returns_up_to_terminator
    @pool.input_queue << "something"
    @pool.input_queue << OutputThreadPool::TERMINATE_WORK
    @pool.input_queue << "something else"
    data = @pool.grab_num_from_queue(@pool.input_queue,@pool.input_queue.size)
    assert_equal 1, data.first.size
    assert !data.last
  end

end
