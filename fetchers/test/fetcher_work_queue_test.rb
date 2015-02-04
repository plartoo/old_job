require File.dirname(__FILE__) + '/test_helper'

class FetcherWorkQueueTest < Test::Unit::TestCase

  def setup
    @queue = FetcherWorkQueue.new
  end

  def test_load_data_onto_queue
    data = [1,2]
    type = 'some type'
    @queue.load_data_onto_queue(data,type)
    data.each do |datum|
      expected = {:work => datum, :type => type}
      assert_equal expected, @queue.pop
    end
  end

  def test_shutdown_sets_shutdown_to_true
    @queue.shutdown
    assert @queue.shutdown?
  end

  def test_shutdown_is_initially_false
    assert !@queue.shutdown?
  end

  def test_to_array_returns_correct_array_of_items
    num = 5
    num.times do |n|
      @queue << n
    end
    assert_equal [0..num],@queue.to_array
  end
  
  def test_to_array_returns_correct_array_of_items
    num = 5
    num.times do |n|
      @queue << n
    end
    arr = @queue.to_array
    num.times do |n|
      assert_equal n, @queue.pop
    end
  end

  def test_pushing_prioritized_pushes_onto_correct_queue
    item = mock(:prioritized? => true)
    @queue << item
    assert_equal 0, @queue.normal.size
    assert_equal 1, @queue.prioritized.size
  end

  def test_pop_returns_poll_again_if_empty
    assert_equal FetcherThreadPool::POLL_AGAIN, @queue.pop
  end

  def test_popping_pops_from_prioritized_when_it_exists
    prioritized1 = mock()
    prioritized1.expects(:prioritized?).returns(true).times(2)
    prioritized2 = mock()
    prioritized2.expects(:prioritized?).returns(true).times(2)
    non_prioritized1 = mock()
    non_prioritized1.expects(:prioritized?).returns(false).times(2)
    non_prioritized2 = mock()
    non_prioritized2.expects(:prioritized?).returns(false).times(2)
    non_prioritized3 = mock()
    non_prioritized3.expects(:prioritized?).returns(false).times(2)
    non_prioritized4 = mock()
    non_prioritized4.expects(:prioritized?).returns(false).times(2)
    @queue << non_prioritized1
    @queue << non_prioritized2
    @queue << prioritized1
    @queue << non_prioritized3
    @queue << prioritized2
    @queue << non_prioritized4

    #make sure two prioritized come back
    assert (@queue.pop).prioritized?
    assert (@queue.pop).prioritized?
    #make sure then the four non-prioritized come back
    assert !(@queue.pop).prioritized?
    assert !(@queue.pop).prioritized?
    assert !(@queue.pop).prioritized?
    assert !(@queue.pop).prioritized?
  end
  
  def test_max_queued_returns_false_when_less_than_limit
    @queue.max_size = 10
    @queue << "something"
    assert !@queue.max_queued?
  end

  def test_max_queued_returns_false_when_max_not_defined
    @queue.max_size = nil
    @queue << "something"
    assert !@queue.max_queued?
  end

  def test_max_queued_returns_true_when_at_capacity
    @queue.max_size = 1
    @queue << "something"
    assert @queue.max_queued?
  end

  def test_max_queued_returns_true_when_over_capacity
    @queue.max_size = 1
    @queue << "something"
    @queue << "something"
    @queue << "something"
    @queue << "something"
    assert @queue.max_queued?
  end

  def test_empty_returns_true_when_size_is_zero
    assert @queue.size == 0
    assert @queue.empty?
  end

  def test_empty_returns_false_when_size_is_not_zero
    assert 0 == @queue.size
    @queue << "something"
    assert 1 == @queue.size
    assert !@queue.empty?
  end
  
end
