require File.dirname(__FILE__)+"/fetcher_framework"

require 'fetcher_work_queue'
require 'full_priced_index_scraper_thread_pool'
require 'item_sccs_thread_pool'
require 'full_priced_output_thread_pool'
require 'closed_list'
require File.dirname(__FILE__)+'/html_logger/item_html_logger'

require 'optparse'
require 'data_sender'

class FullPricedFetcherFramework < FetcherFramework

  def setup
    return if @setup_complete

    Agent.data_sender = @data_sender if @data_sender

    @fetcher = spawn_and_configure_fetcher
    
    @fetcher.log.info("Fetching #{@fetcher_name}")
    @fetcher.log.info "Starting at #{Time.now} for #{@date}"

    @options = grab_options

    @setup_complete = true
  end

  def create_logger
    @fetcher_class.create_logger(@log_path, "#{@log_file || @fetcher_class_name}_#{@date}.log", "a+")
  end

  def self.parse_category_scraping_options
    input_options = {:i18n_version => "us", :time_limit_in_mins => 60*20, :num_threads => 3,
                      :data_sender_host => "127.0.0.1", :data_sender_port => "1230", :log_file => nil }
    OptionParser.new do |opts|
      opts.banner = "Usage: ./bin/category_scrape.rb [options]"
      opts.on("-i I18N_VERSION", "--i18n_version", "I18n_version to use. Default => #{input_options[:i18n_version]}") do |x|
        input_options[:i18n_version] = x
      end
      opts.on("-f FETCHER_NAME", "--fetcher_name", "Fetcher name run. Example: \"all_saints\".") do |x|
        input_options[:fetcher_name] = x
      end
      opts.on("-t TIME_LIMIT_IN_MINS", "--time_limit", "Time limit to run. Default is #{input_options[:time_limit_in_mins]}.") do |x|
        input_options[:time_limit_in_mins] = x
      end
      opts.on("-n NUM_THREADS", "--num_threads", "Number of threads to use. Default is #{input_options[:num_threads]}.") do |x|
        input_options[:threaded] = x
      end
      opts.on("-h DATA_SENDER_HOST", "--data_sender_host", "Host of stats accumulator. Default is #{input_options[:data_sender_host]}.") do |x|
        input_options[:data_sender_host] = x
      end
      opts.on("-p DATA_SENDER_PORT", "--data_sender_port", "Port for stats accumulator. Default is #{input_options[:data_sender_port]}.") do |x|
        input_options[:data_sender_port] = x
      end
      opts.on("-l LOG_FILE", "--log_file", "Log file to use. Default is, for example, \"Yoox_2011-03-24.log\".") do |x|
        input_options[:log_file] = x
      end
      opts.on("-o OUTPUT_PATH", "--output_path", "Output path to store files. Default is, for example, \"partial-items/2011-03-24/all_saints\".") do |x|
        input_options[:output_path] = x
      end
      opts.on("-d FINAL_ITEMS_DESTINATION", "--items_destination", "Folder to move items to after output_path. Default is, for example, \"items/2011-03-24/\".") do |x|
        input_options[:final_output_path] = x
      end
    end.parse!
    raise "Invalid i18n_version parameter set: \"#{input_options[:i18n_version]}\". Valid options are \"us\" and \"uk\"" unless input_options[:i18n_version] =~ /us|uk/
    raise "No fetcher_name parameter set: \"#{input_options[:fetcher_name]}\"." if input_options[:fetcher_name].nil?

    input_options
  end

  def self.parse_detail_scraping_options
    input_options = {:i18n_version => "us", :num_threads => 3, 
                      :data_sender_host => "127.0.0.1", :data_sender_port => "1230", :log_file => nil }
    OptionParser.new do |opts|
      opts.banner = "Usage: ./bin/detail_scrape.rb [options]"
      opts.on("-i I18N_VERSION", "--i18n_version", "I18n_version to use. Default => #{input_options[:i18n_version]}") do |x|
        input_options[:i18n_version] = x
      end
      opts.on("-h DATA_SENDER_HOST", "--data_sender_host", "Host of stats accumulator. Default is #{input_options[:data_sender_host]}.") do |x|
        input_options[:data_sender_host] = x
      end
      opts.on("-p DATA_SENDER_PORT", "--data_sender_port", "Port for stats accumulator. Default is #{input_options[:data_sender_port]}.") do |x|
        input_options[:data_sender_port] = x
      end
      opts.on("-l LOG_FILE", "--log_file", "Log file to use. Default is, for example, \"path/to/input_file.yml.fetcher.log\".") do |x|
        input_options[:log_file] = x
      end
      opts.on("-o OUTPUT_PATH", "--output_path", "Output path to store files. Default is, for example, \"items-with-details/2011-03-24/all_saints\".") do |x|
        input_options[:output_path] = x
      end
    end.parse!
    raise "Invalid i18n_version parameter set: \"#{input_options[:i18n_version]}\". Valid options are \"us\" and \"uk\"" unless input_options[:i18n_version] =~ /us|uk/

    input_options[:files] = ARGV
    input_options
  end

  
end