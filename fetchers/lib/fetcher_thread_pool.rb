require 'fileutils'

class FetcherThreadPool

  TERMINATE_WORK = "Stop working"
  CATEGORY_TO_SCRAPE = "Scrape this category"
  ITEM_FOR_SCCS = "Fetch SCC info for this item"
  POLL_AGAIN = "Nothing enqueued, poll again."
  SKIP_WORK = "Skip and try again"
  ALL_DONE = "Done working"

  class FetcherThreadPoolError < StandardError; end
  class NoSpawnThreadMethodDefined < FetcherThreadPoolError; end
  
  attr_accessor :configuration, :input_queue, :threads

  def initialize(configuration)
    @configuration = configuration
    @fetcher_class = configuration[:fetcher_class]
    @threads = []
  end

  def size
    @threads.size
  end

  def run
    @configuration[:num_threads].times do
      @threads << spawn_and_return_thread
    end
  end

  def fetcher_has_time_left?(time_now = Time.now.to_i)
    return true if @configuration[:time_to_stop].nil?

    @configuration[:time_to_stop] > time_now
  end

  def spawn_and_return_thread
    raise NoSpawnThreadMethodDefined, "Must define spawn_and_return_thread method in subclass"
  end
end