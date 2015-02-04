require File.dirname(__FILE__)+"/full_priced_fetcher_framework"

class FullPricedCategoryScraperFramework < FullPricedFetcherFramework

  attr_accessor :item_scraper

  def run
    @start_time = Time.now.to_f
    setup

    @cats_from_file = grab_categories(['full_price_'])
    @cats_from_file[:active].map{|cat| cat.prioritized = true; cat}
    index_work_queue = FetcherWorkQueue.new
    index_work_queue.load_data_onto_queue(@cats_from_file[:active],IndexScraperThreadPool::CATEGORY_TO_SCRAPE)

    @item_queue = FetcherWorkQueue.new

    @config_data = prepare_and_return_config
    
    vendor_key_closed_list = []
    
    @index_thread_pool = FullPricedIndexScraperThreadPool.new(@config_data.merge({
                            :uncategorized_html_logger => @uncategorized_clothing_logger,
                            :vendor_key_closed_list => vendor_key_closed_list,
                            :item_scraper_valid_counter => ThreadSafeCounter.new,
                            :item_scraper_total_counter => ThreadSafeCounter.new,
                            :data_sender => @data_sender,
                            :index_work_queue => index_work_queue,
                            :full_price_items => true,
                            :item_sccs_queue => @item_queue,
                            :num_threads => @num_item_scraper_threads,
                            :fetcher_class => @fetcher_class,
                           }))
                       
    @index_thread_pool.run
    
    @output_thread_pool = FullPricedOutputThreadPool.new(@config_data.merge({:output_path => @output_path, :num_threads => 1,}))
    @output_thread_pool.run

    @index_thread_pool.join
    @output_thread_pool.join

    @final_stats = {:successfully_scraped_count => @output_thread_pool.output_counter,
                    :duplicate_items_written_out => @output_thread_pool.duplicate_output_counter.value,}
    cleanup
  end

  def cleanup
    if @failed_item_counter.value > 0
      @fetcher.log.warn("couldn't get size color configs for #{@failed_item_counter}")
    end

    @fetcher.log.info("wrote #{@output_thread_pool.output_counter} (#{@output_thread_pool.duplicate_output_counter} duplicates) items to #{@output_path}\n\n")
    print_final_fetch_results(@start_time, Time.now.to_f)

    @fetcher.log.info("About to move files in #{@output_path} into #{@final_output_path}")
    FileUtils.mkdir_p @final_output_path
    move_batches_from_to(@output_path,@final_output_path)
    `rm -r #{@output_path}`

    @fetcher.log.info("All done!")
    @fetcher.log.close
  end

  def move_batches_from_to(from,to)
    file_chars = (0..9).entries + ("a".."f").entries
    file_chars.each do |char|
      run_cmd("mv #{from}/#{char}* #{to}/")
    end
  end

  def run_cmd(cmd)
    `#{cmd}`
  end

  def grab_options(time_now = Time.now.to_i)
    options = {}
    options[:time_to_stop] = time_now + @time_limit_in_mins.to_i * 60

    options
  end

  def prepare_and_return_config
    vendor_key_closed_list = ClosedList.new

    @failed_item_counter = ThreadSafeCounter.new

    forbidden_brands = @fetcher.get_forbidden_brand_bms(@fetcher_name)

    config_data = {:forbidden_brands => forbidden_brands,
                   :item_scraper_valid_counter => ThreadSafeCounter.new,
                   :item_scraper_total_counter => ThreadSafeCounter.new,
                   :processed_item_counter => ThreadSafeCounter.new,
                   :failed_item_counter => @failed_item_counter,
                   :vendor_key_closed_list => vendor_key_closed_list,
                   :output_queue => @item_queue,
                   :date => @date.strftime("%y%m%d"),
                  }

    config_data
  end
  


end