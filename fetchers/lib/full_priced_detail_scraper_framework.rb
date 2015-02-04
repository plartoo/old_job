require File.dirname(__FILE__)+"/full_priced_fetcher_framework"

class FullPricedDetailScraperFramework < FullPricedFetcherFramework

  attr_accessor :fetcher_name

  @@fetcher_objects = {}

  def setup
    return if @setup_complete
    
    super

    SCCScraper.grab_extended_description = true
    SCCScraper.grab_additional_images = true
    SCCScraper.grab_related_vendor_keys = true
    
    Item.validate_sale_price = false
  end

  def spawn_and_configure_fetcher
    unless @@fetcher_objects[@fetcher_name]
      fetcher = FetcherHelperMethods.spawn_new_fetcher_instance(@fetcher_class_name,@fetcher_name)
      create_logger(fetcher.class)
      @@fetcher_objects[@fetcher_name] = fetcher
    end

    @fetcher_class = @@fetcher_objects[@fetcher_name].class
    @fetcher_class.i18n_version = @i18n_version

    @@fetcher_objects[@fetcher_name]
  end

  def create_logger(fetcher_class)
    fetcher_class.create_logger(File.dirname(@log_path), File.basename(@log_path), "a+")
  end

  def run
    setup
    
    File.open(@item_log_path,"w") do |item_log_file|
      start = Time.now.to_f

      @fetcher.sccs_scrape_single_item({:item => @item, :data_sender => @data_sender})

      finalize_item
      
      fin = Time.now.to_f
      item_log_file.puts "#{@fetcher_name}\t#{start}\t#{fin}\t#{@key}"
    end

  end

  def finalize_item
    if @item.valid? && @item.scc && @item.scc.any? && !@fetcher.is_forbidden_brand_item?(@item, :forbidden_brands=>@fetcher.get_forbidden_brand_bms(fetcher_name))

      begin
        @item.product_image.resize_to_max
      rescue => e
      end

      File.open(@output_file, "w") do |f|
        f.puts @item.to_hash.to_yaml
      end

      @data_sender.send("#{@fetcher_class.data_sender_short_name}_det_suc",1) if @data_sender
      @data_sender.send("aggregate_det_suc",1) if @data_sender
    else
      @fetcher.log.info "Failed to scrape details."
      @fetcher.log.info @item.inspect
      @data_sender.send("#{@fetcher_class.data_sender_short_name}_det_fail",1) if @data_sender
      @data_sender.send("aggregate_det_fail",1) if @data_sender
    end
  end

  def self.fetcher_objects
    @@fetcher_objects
  end
end
