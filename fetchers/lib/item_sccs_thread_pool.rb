require 'fetcher_thread_pool'

class ItemSccsThreadPool < FetcherThreadPool

  attr_accessor :output_queue, :input_queue

  def initialize(configuration)
    super(configuration)
    @input_queue = configuration[:item_sccs_queue]
    @output_queue = configuration[:output_queue]
  end
  
  def join
    @input_queue.load_data_onto_queue((0..@configuration[:num_threads]-1).to_a,TERMINATE_WORK)
    @threads.each{|thr| thr.join}
  end

  def spawn_and_return_thread
    Thread.new do
      fetcher = FetcherHelperMethods.spawn_new_fetcher_instance(@fetcher_class.to_s,@fetcher_class.fetcher_name)
      data = @input_queue.pop
      while data
        if data[:type] == TERMINATE_WORK
          break
        elsif data[:type] == ITEM_FOR_SCCS
          scrape_sccs_info(fetcher, data[:work])
        end

        break unless fetcher_has_time_left?
        data = @input_queue.pop
      end
    end
  end

  def scrape_sccs_info(fetcher, item)
    fetcher.scrape_sccs(@configuration.merge({:item => item,:output_queue => @output_queue}))
  end
  
end