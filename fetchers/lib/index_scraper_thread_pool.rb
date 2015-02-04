require 'fetcher_thread_pool'

class IndexScraperThreadPool < FetcherThreadPool

  attr_accessor :item_sccs_queue, :index_work_queue, :input_queue, :output_queue, :finished_threads

  def initialize(configuration)
    super(configuration)
    @time_to_stop = configuration[:time_to_stop]
    @input_queue = configuration[:index_work_queue]
    @output_queue = configuration[:item_sccs_queue]
    @full_price_items = configuration[:full_price_items]
    @uncategorized_clothing_type_logger = configuration[:uncategorized_clothing_type_logger]
    @finished_threads = Queue.new
  end
  
  def join
    while fetcher_has_time_left?
      break if all_threads_finished?

      sleep(1)
      Thread.pass
    end

    @input_queue.shutdown
    @threads.each{|thr| thr.join}
  end

  def create_item_scraper
    ItemScraper.new(@fetcher_class, @fetcher_class.items_options.merge({:uncategorized_clothing_type_logger => @uncategorized_clothing_type_logger}),
          &@fetcher_class.items_definition)
  end

  def spawn_and_return_thread
    Thread.new do
      item_scraper = create_item_scraper

      while data = @input_queue.pop
        if data[:type] == TERMINATE_WORK
          break
        elsif data[:type] == CATEGORY_TO_SCRAPE
          scrape_items_from_cat(data[:work],item_scraper)
        end

        #would have pushed more work already if more existed
        break if @input_queue.empty? || !fetcher_has_time_left?
        
      end
      @finished_threads << ALL_DONE
    end
  end

  def scrape_items_from_cat(category,item_scraper)
    begin
      num_items_from_cat,category = item_scraper.scrape({:cat => category,
                                             :full_price_items => @full_price_items,
                                             :coupons => @configuration[:coupons],
                                             :item_scraper_valid_counter => @configuration[:item_scraper_valid_counter],
                                             :item_scraper_total_counter => @configuration[:item_scraper_total_counter],
                                             :item_sccs_queue => @output_queue,
                                             :time_to_stop => @time_to_stop,
                                             :vendor_key_closed_list => @configuration[:vendor_key_closed_list],
                                             :data_sender => @configuration[:data_sender]})
      if category
        @input_queue << {:type => CATEGORY_TO_SCRAPE, :work => category}
      end

      num_items_from_cat #for testing
    rescue Exception => e
      @fetcher_class.log.error(e.to_s)
      @fetcher_class.log.error(e.backtrace.join("\n"))
    end
  end

  def all_threads_finished?
    @finished_threads.size == @configuration[:num_threads]
  end

  
end