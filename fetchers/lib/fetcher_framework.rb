require 'fetcher'
require 'fileutils'
require 'yaml'
require 'i18n_version'

class FetcherFramework

  attr_accessor :html_uncat_file, :uncategorized_output_stream, :time_limit_in_mins, :fetcher
  attr_accessor :cats_from_file, :options, :fetcher_class

  class FetcherFrameworkError < StandardError; end
  class InvalidParameters < FetcherFrameworkError; end

  def initialize(options = {})
    options.each{|name,value|
      self.instance_variable_set("@#{name}",value)
    }

    raise InvalidParameters unless @i18n_version
    
    I18nVersion.set!(@i18n_version)

    Configuration.application = @i18n_version
    ClothingTypeMatcher.i18n_version = @i18n_version
    
    @final_stats = {}
  end

  def setup
    return if @setup_complete
    
    @fetcher = spawn_and_configure_fetcher

    @fetcher.log.info "Beginning #{self.class} run"
    @fetcher.log.info "Starting at #{Time.now} for #{@date}"
    @fetcher.log.info("Fetching #{@fetcher_name}")

    @coupons = grab_coupons
    @cats_from_file = grab_categories
    @uncategorized_clothing_logger = create_uncategorized_clothing_logger

    @options = grab_options

    @setup_complete = true
  end

  def spawn_and_configure_fetcher
    fetcher = FetcherHelperMethods.spawn_new_fetcher_instance(@fetcher_class_name,@fetcher_name)

    @fetcher_class = fetcher.class
    create_logger
    @fetcher_class.i18n_version = @i18n_version

    fetcher
  end

  def create_logger
    @fetcher_class.create_logger(File.join(File.dirname(__FILE__),'..','log'), "#{@fetcher_class_name || 'fetch'}_#{@i18n_version}.log", "a+")
  end

  def cleanup(testing = false)
    if @html_log_uncat && @uncategorized_output_stream
      @uncategorized_output_stream.close
    end

    @fetcher_class.log.close unless testing
  end

  def grab_options(time_started = Time.now.to_i)
    options = {}
    options[:time_limit_in_mins] = @time_limit_in_mins ? @time_limit_in_mins.to_i : nil
    options[:time_started] = time_started
    if options[:time_limit_in_mins]
      options[:time_limit_in_mins] = [1,options[:time_limit_in_mins] - 2].max #two minute warning
      options[:time_limit_in_seconds] = options[:time_limit_in_mins] * 60
      options[:time_to_stop] = options[:time_started] + options[:time_limit_in_seconds]
    end

    options
  end

  def time_run_out?(time_now = Time.now.to_i)
    @options[:time_to_stop] && @options[:time_to_stop] < time_now
  end

  def create_uncategorized_clothing_logger
    uncategorized_clothing_logger = nil
    if @html_log_uncat
      html_uncat_file = "log/#{@fetcher_name}_uncategorized_clothing_#{@date.strftime("%y%m%d")}.html"
      @uncategorized_output_stream = File.open(html_uncat_file,"w")
      uncategorized_clothing_logger = ItemHtmlLogger.new(@uncategorized_output_stream)
    end

    uncategorized_clothing_logger
  end

  def grab_categories(additional_folders = [])
    begin
      cats_from_file = @fetcher.get_categories(additional_folders)
    rescue Exception => e
      @fetcher.log.error(e.to_s)
      @fetcher.log.error(e.backtrace.join("\n"))
    end

    cats_from_file
  end

  def grab_coupons
    coupons = @fetcher_class.get_coupons(@date) || []
    @fetcher_class.log.info("loaded #{coupons.size} coupon(s)")
    if coupons.any?
      @fetcher_class.log.info %Q(Coupons are\n#{coupons.map{|c| c.to_yaml}.join("\n")})
    end
    
    coupons
  end

  def print_final_fetch_results(start_time,end_time)
    if @final_stats[:failed_item_count] && @final_stats[:failed_item_count] > 0
      @fetcher_class.log.warn("couldn't get size color configs for #{@final_stats[:failed_item_count]}")
    end

    summary = "SUMMARY of sccs scraping::"
    counts = "Number of items with successful SCCS scraping: #{@final_stats[:successfully_scraped_count]} (#{@final_stats[:duplicate_items_written_out] || 0} duplicates) out of #{@final_stats[:total_valid_count]} valid items.\n"
    @fetcher_class.log.info(summary+"\n"+counts)
    puts summary+"\n"+counts

    @fetcher_class.log.info("wrote #{@final_stats[:successfully_scraped_count]} items to file\n\n")

    begin
      total = ((end_time && start_time) ? end_time - start_time : 'not available')
      total_time_taken = "\n\nTotal time taken::\n\nTotal of item and scc scraping: #{total}\n\n"

      puts total_time_taken
      @fetcher_class.log.info total_time_taken
    rescue Exception => e
      @fetcher_class.log.error("Error in time reporting\n#{e.to_s}")
    end
    
  end

  def self.create_framework_obj(framework_setup_options,framework_type)
    if framework_type.eql?(:multithread)
      require File.dirname(__FILE__) + "/multithread_framework"
      MultithreadFramework.new(framework_setup_options)
    elsif framework_type.eql?(:singlethread)
      require File.dirname(__FILE__) + "/singlethread_framework"
      SinglethreadFramework.new(framework_setup_options)
    elsif framework_type.eql?(:assisted_checkout)
      require File.dirname(__FILE__) + "/assisted_checkout_framework"
      AssistedCheckoutFramework.new(framework_setup_options)
    end
  end

  def run
    raise "run() must be redefined in child class."
  end

end
