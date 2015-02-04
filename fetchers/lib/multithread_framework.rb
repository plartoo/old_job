require 'fetcher_work_queue'
require 'index_scraper_thread_pool'
require 'item_sccs_thread_pool'
require 'output_thread_pool'
require 'closed_list'
require File.dirname(__FILE__)+"/fetcher_framework"

class MultithreadFramework < FetcherFramework

  attr_accessor :index_thread_pool, :item_sccs_thread_pool, :output_thread_pool, :config_data
  attr_accessor :failed_item_counter, :item_scraper_valid_counter

  MAX_QUEUED_SCCS_ITEMS = nil #50

  def setup
    super

    @config_data = prepare_and_return_config
  end

  def run
    setup
    
    @index_thread_pool = IndexScraperThreadPool.new(@config_data.merge(:num_threads => @num_item_scraper_threads,
                                                                      :full_price_items => @coupons.any?,
                                                                      :uncategorized_clothing_type_logger => @uncategorized_clothing_logger))
    @index_thread_pool.run
    
    @item_sccs_thread_pool = ItemSccsThreadPool.new(@config_data.merge(:num_threads => @num_sccs_threads))
    @item_sccs_thread_pool.run

    @output_thread_pool = OutputThreadPool.new(@config_data.merge(:num_threads => 1))
    @output_thread_pool.run
    
    join_and_return_stats
  end

  def join_and_return_stats
    @index_thread_pool.join
    @item_sccs_thread_pool.join
    @output_thread_pool.join

    @final_stats = {
      :successfully_scraped_count => @output_thread_pool.output_counter.value,
      :total_valid_count => @item_scraper_valid_counter.value,
      :failed_item_count => @failed_item_counter.value,
      :duplicate_items_written_out => @output_thread_pool.duplicate_output_counter.value,
    }
  end
  
  def prepare_and_return_config
    index_work_queue = FetcherWorkQueue.new
    item_sccs_queue = FetcherWorkQueue.new(MAX_QUEUED_SCCS_ITEMS)
    output_queue = FetcherWorkQueue.new

    active_categories = @cats_from_file[:active].map{|cat| cat.prioritized = true; cat}
    index_work_queue.load_data_onto_queue(active_categories,IndexScraperThreadPool::CATEGORY_TO_SCRAPE)

    vendor_key_closed_list = ClosedList.new

    processed_item_counter = ThreadSafeCounter.new
    @failed_item_counter = ThreadSafeCounter.new
    @item_scraper_valid_counter = ThreadSafeCounter.new
    item_scraper_total_counter = ThreadSafeCounter.new

    forbidden_brands = @fetcher.get_forbidden_brand_bms(@fetcher_name)
    feed_path = @feed_path || "yaml_feeds/#{@i18n_version}"
    
    config_data = {:out_to_console => @out_to_console,
                   :coupons => @coupons,
                   :forbidden_brands => forbidden_brands,
                   :index_work_queue => index_work_queue,
                   :item_sccs_queue => item_sccs_queue,
                   :output_queue => output_queue,
                   :item_scraper_valid_counter => @item_scraper_valid_counter,
                   :item_scraper_total_counter => item_scraper_total_counter,
                   :processed_item_counter => processed_item_counter,
                   :failed_item_counter => @failed_item_counter,
                   :vendor_key_closed_list => vendor_key_closed_list,
                   :feed_path => feed_path,
                   :fetcher_class => @fetcher_class,
                   :date => @date.strftime("%y%m%d"),
                       }.merge(@options)

    config_data
  end

  

end