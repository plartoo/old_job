require File.dirname(__FILE__)+"/fetcher_framework"

class SinglethreadFramework < FetcherFramework

  def run
    setup
    
    items = scrape_items_from_categories
    @fetcher.log.info("fetched #{items.size} items in total")

    items.sort! {|a, b| rand() <=> rand()}
    @options[:coupons] = @coupons

    setup_sccs_counters
    
    scrape_sccs_data_for items

    stats = write_out_items
    
    @final_stats = {
      :successfully_scraped_count => @options[:output_queue].size,
      :total_valid_count => items.size,
      :failed_item_count => @options[:failed_item_counter].value,
      :duplicate_items_written_out => stats[:duplicate_items_written_out],
    }
  end

  def setup_sccs_counters
    processed_items_counter = ThreadSafeCounter.new
    failed_items_counter = ThreadSafeCounter.new

    @options[:output_queue] = []
    @options[:processed_item_counter] = processed_items_counter
    @options[:failed_item_counter] = failed_items_counter
  end

  def scrape_items_from_categories(time_now = Time.now.to_i)
    item_scraper = ItemScraper.new(@fetcher_class, @fetcher_class.items_options.merge({:uncategorized_clothing_type_logger => @uncategorized_clothing_type_logger}),
          &@fetcher_class.items_definition)

    items = []
    vendor_key_closed_list = []

    item_scraper_options = {:coupons => @coupons,
                            :uncategorized_html_logger => @uncategorized_clothing_logger,
                            :vendor_key_closed_list => vendor_key_closed_list,
                            :item_scraper_valid_counter => ThreadSafeCounter.new,
                            :item_scraper_total_counter => ThreadSafeCounter.new,
                            :time_to_stop => @options[:time_to_stop],
                            :data_sender => @options[:data_sender],
                           }
                           
    while cat = @cats_from_file[:active].shift
      break if time_run_out?(time_now)
      
      items.concat do_category_and_get_items(cat,item_scraper,item_scraper_options)
    end

    items
  end

  def do_category_and_get_items(cat,item_scraper,item_scraper_options)
    begin
      items_from_cat = items_from_category(cat,item_scraper,item_scraper_options)
      
      @fetcher.log.info("fetched #{items_from_cat.size} items from '#{cat.name}' on page #{cat.paginator_iterations}")

      items_from_cat
    rescue Exception => e
      @fetcher.log.error(e.to_s)
      @fetcher.log.error(e.backtrace.join("\n"))
      []
    end
  end

  def items_from_category(cat,item_scraper,item_scraper_options)
    items_from_cat = []
    num_items_from_cat,category = item_scraper.scrape(item_scraper_options.merge({:item_sccs_queue => items_from_cat, :cat => cat}))
                             
    if category
      @cats_from_file[:active] << category
    end
    items_from_cat.map!{|work_item| work_item[:work]}

    items_from_cat
  end

  def scrape_sccs_data_for(items, time_now = Time.now.to_i)
    items.each do |item|
      break if time_run_out?(time_now)

      @fetcher.scrape_sccs(@options.merge({:item => item}))
    end
  end

  def write_out_items
    feed_path = @feed_path || "yaml_feeds/#{@i18n_version}"
    stats = @fetcher_class.write_to_yaml(feed_path, @fetcher_name, @options[:output_queue], @date)
    
    stats
  end

end