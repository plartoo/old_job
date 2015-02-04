#!/usr/bin/env ruby

# scrapes the categories for a particular retailer producing one (with sizes omitted) yaml file per item
# for subsequent size scraping

# usage ./bin/category_scrape.rb --help

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", 'lib'))

require 'rubygems'
require 'full_priced_category_scraper_framework'

$output_mechanize_resp_size_to = '../shared/'
FileUtils.mkdir_p($output_mechanize_resp_size_to)
$output_mechanize_resp_size_to += 'request_size_data.tsv'

$key = ""

input_options = FullPricedFetcherFramework.parse_category_scraping_options

# name and module
fetcher_name = input_options[:fetcher_name]
fetcher_class_name = FetcherHelperMethods.get_fetcher_class_name_from_name(fetcher_name)

date = Date.today

# log
log_path = File.join("log",date.to_s)

data_sender = DataSender.new(input_options[:data_sender_host],input_options[:data_sender_port])

output_path = input_options[:output_path] || File.join("partial-items",Date.today.to_s,fetcher_name)
FileUtils.mkdir_p output_path

input_options[:final_output_path] ||= File.join("items",Date.today.to_s,fetcher_name)

options = {
  :time_limit_in_mins => input_options[:time_limit_in_mins],
  :i18n_version => input_options[:i18n_version],

  :date => date,
  :data_sender => data_sender,
  :output_path => output_path,
  :log_file => input_options[:log_file],
  :log_path => log_path,
  :final_output_path => input_options[:final_output_path],

  :num_item_scraper_threads => input_options[:num_threads],
  
  :fetcher_name => fetcher_name,
  :fetcher_class_name => fetcher_class_name,
}

framework = FullPricedCategoryScraperFramework.new(options)
framework.run
