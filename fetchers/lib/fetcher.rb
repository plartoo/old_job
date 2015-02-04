require File.dirname(__FILE__) + "/dependencies"


require 'category_fetcher'
require 'item_fetcher'
require 'logger'
require 'scc_javascript_scraper'
require 'scc_hashed_json_scraper'
require 'scc_custom_scraper'
require 'scc_html_scraper'
require 'scc_ajax_scraper'
require 'scc_manual_scraper'
require 'size_mapper'
require 'severity_formatter'
require 'agent'
require 'yaml'
require 'utils'
require 'jpeg'
require 'fetcher_work_queue'
require 'fetcher_thread_pool'
require 'thread_safe_counter'
require 'i18n_version'

require 'fetcher_instance'
require 'fetcher_helper_methods'

#### Commenting out environment check as of 3/30/11, since we have
#### upgraded Nokogiri gem to version 1.4.4 to fix seg faults.
# verify environment is sane
#require 'environment_check'
#abort(EnvironmentCheck::ERROR) unless EnvironmentCheck.new.check_environment

begin
 require 'ruby-debug'
rescue Exception => ignored
  class Object
    def debugger
       puts "WARNING: debugger called and ruby-debug gem not found"
    end
  end
end

module Fetcher

  attr_reader :setup_block, :category_scrapers
  attr_reader :sccs_scraper_type, :sccs_def
  attr_reader :items_options, :items_definition
  attr_accessor :log, :i18n_version, :fetcher_name, :path

  @log = nil
  @path = nil
  @category_scrapers = nil
  @i18n_version = nil
  @setup_block = nil
  @name = nil
  @fetcher_name = nil
  @items_options = nil
  @items_definition = nil

  @load_fetcher_file = false

  def setup(&block)
    @setup_block = block
  end

  # left from the original single threaded
  def categories(options, &definition)
    unless options[:ignore_categories]
      @category_scrapers ||= []
      @category_scrapers << CategoryScraper.new(self, options, &definition)
    end
  end

  def items(options, &definition)
    unless block_given?
      raise "no item definition given"
    end
    @items_options = options
    @items_definition = definition
  end

  def sccs(type, &definition)
    unless block_given?
      raise "no scc definition given"
    end
    @sccs_scraper_type = type
    @sccs_def = definition
  end

  def get_coupons(date) # :nodoc:
    SitewideCoupon.load_from_sitm(@fetcher_name, date)
  end

  def populate_category_file_paths(file_names)
    category_files = []

    fetcher_path = @path.gsub(/\.rb$/,"")

    file_names.each do |ext|
      cat_path = fetcher_path + "_#{ext}categories.#{@i18n_version}.yml"
      category_files.push(cat_path) if File.exist?(cat_path)
    end
    
    category_files
  end

  def write_to_yaml(feeds_dir, fetcher_name, items, date) # :nodoc:
    yaml_feed = File.join(feeds_dir, fetcher_name)
    unless File.exist?(yaml_feed)
      FileUtils.mkdir_p(yaml_feed)
    end

    yaml_feed = File.join(yaml_feed, "#{date.strftime("%y%m%d")}.yml")
    seen_vendor_keys = []
    duplicates = 0
    File.open(yaml_feed, "w+") do |f|
      f.puts((items.map {|item|
            if seen_vendor_keys.include?(item.vendor_key)
              duplicates += 1
            end
            seen_vendor_keys << item.vendor_key
            item.to_hash
      }).to_yaml)
    end
    {:duplicate_items_written_out => duplicates}
  end

  # TODO: remove necessity of dir and filename options
  def create_logger(dir, filename, options=nil) # :nodoc:
    options ||= "a+"
    unless File.exist?(dir)
      FileUtils.mkdir_p(dir)
    end
    file = File.open(File.join(dir, filename), options)
    @log = Logger.new(file)
    @log.formatter = FetcherFormatter.new
    @log.level = Logger::INFO
    @log
  end

  def data_sender_short_name
    @fetcher_name[0..9]
  end

  class FetcherFormatter < SeverityFormatter
    def call(severity, time, program_name, message)
      fractional_seconds = "%03d" % (time.usec/1000) #usec/1000 = # milliseconds
      "[#{time.strftime('%Y-%m-%d %H:%M:%S')}.#{fractional_seconds}] [#{severity}] #{message}\n"
    end
  end

end


