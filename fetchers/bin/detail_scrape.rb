#!/usr/bin/env ruby

# scrapes the item details for passed in items

# usage ./bin/detail_scrape.rb --help

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", 'lib'))

require 'rubygems'
require 'full_priced_detail_scraper_framework'

$output_mechanize_resp_size_to = '../shared/request_size_data.tsv'

input_options = FullPricedFetcherFramework.parse_detail_scraping_options

# for tracking stats
data_sender = DataSender.new(input_options[:data_sender_host],input_options[:data_sender_port])

input_options[:files].each do |file_name|
  # load item
  item = Item.load_from_hash(YAML::load_file(file_name))

  # log
  log_path  = input_options[:log_file] || file_name + ".fetcher.log"

  fetcher_name, fetcher_class_name = FetcherHelperMethods.get_fetcher_names_from_item(item)

  # for logging
  key = File.basename(file_name).gsub(".yml","")

  $key = key
  
  item_log_path = File.join("log",Date.today.to_s,fetcher_name,"detail_scrape_#{key}.log")
  FileUtils.mkdir_p File.dirname(item_log_path)

  # create output path
  output_path = input_options[:output_path] || File.join("items-with-details",Date.today.to_s,fetcher_name)
  FileUtils.mkdir_p output_path
  output_file = File.join(output_path, File.basename(file_name))

  framework = FullPricedDetailScraperFramework.new({
                                    :item => item,
                                    :data_sender => data_sender,
                                    :item_log_path => item_log_path,
                                    :output_file => output_file,
                                    :key => key,
                                    :log_path => log_path,
                                    :i18n_version => input_options[:i18n_version],

                                    :fetcher_name => fetcher_name,
                                    :fetcher_class_name => fetcher_class_name,
                                   })

  framework.run
  
end
