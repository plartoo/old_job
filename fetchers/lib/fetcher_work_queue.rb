require 'thread'
require 'fetcher_thread_pool'

class FetcherWorkQueue

  SHUTTING_DOWN = "This queue is shutting down."

  attr_accessor :prioritized, :normal, :max_size

  def initialize(max_size = nil)
    @max_size = max_size
    @prioritized = Queue.new
    @normal = Queue.new
    @shutdown = nil
  end
  
  def load_data_onto_queue(data_array,type)
    data_array.each do |datum|
      self << {:type => type, :work => datum}
    end
  end

  def shutdown
    @shutdown = true
  end

  def shutdown?
    @shutdown
  end

  def to_array
    own_queue_to_array(@prioritized).concat(own_queue_to_array(@normal))
  end

  def own_queue_to_array(queue)
    array = []
    begin
      Thread.critical = true
      num_items = queue.length
      while num_items > 0
        item = queue.pop
        array << item
        queue << item
        num_items -= 1
      end
    ensure
      Thread.critical = false
    end
    array
  end

  def max_queued?
    num_queued = @prioritized.size + @normal.size
    @max_size && (num_queued >= @max_size)
  end

  def <<(element)
    Thread.critical = true
    return SHUTTING_DOWN if @shutdown
    
    if !max_queued?
      if (element.respond_to?(:[]) && element[:work].respond_to?(:prioritized?) && element[:work].prioritized?) ||
          (element.respond_to?(:prioritized?) && element.prioritized?)
        @prioritized << element
      else
        @normal << element
      end
      true
    else
      false
    end
  ensure
    Thread.critical = false
  end

  NON_BLOCKING_POP = true
  def pop
    Thread.critical = true

    return FetcherThreadPool::TERMINATE_WORK if @shutdown

    if @prioritized.size > 0
      @prioritized.pop(NON_BLOCKING_POP)
    else
      @normal.pop(NON_BLOCKING_POP)
    end

  rescue ThreadError => e
    FetcherThreadPool::POLL_AGAIN
  ensure
    Thread.critical = false
  end

  def size
    @prioritized.size + @normal.size
  end

  def empty?
    0 == size
  end

  alias_method :push, :<<
  
end