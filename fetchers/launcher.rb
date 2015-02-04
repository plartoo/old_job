require 'rubygems'
require 'optparse'

require File.dirname(__FILE__)+"/lib/launcher"

def parse_options
  options = {:i18n_version => "us", :threaded => false }
  OptionParser.new do |opts|
  opts.banner = "Usage: launcher.rb [options]"
    opts.on("-i I18N_VERSION", "--i18n_version", "I18n_version to use. Default => #{options[:i18n_version]}") do |x|
      options[:i18n_version] = x
    end
    opts.on("-f FETCHER_NAME", "--fetcher_name", "Fetcher name to fetch. For example: \"-f all_saints\".") do |x|
      options[:fetcher_module] = x
    end
    opts.on("-t TIME_LIMIT", "--time_limit", "Fetcher time limit. Default is unlimited.") do |x|
      options[:time_limit] = x
    end
    opts.on("-h", "--threaded", "Include to force use of threaded framework. Default is single thread.") do |x|
      options[:threaded] = x
    end
  end.parse!
  raise "Invalid i18n_version parameter set: \"#{options[:i18n_version]}\". Valid options are \"us\" and \"uk\"" unless options[:i18n_version] =~ /us|uk/

  options
end


options = parse_options

if options[:fetcher_module]
  puts "Launching #{options[:fetcher_module]} fetcher in #{options[:i18n_version]} for #{options[:time_limit] || 'full'}"
  Launcher.new(options[:i18n_version],options[:threaded]).run_and_import_one_fetcher(options[:fetcher_module].downcase, options[:time_limit])
else
  puts "Launching fetchers for #{options[:i18n_version]}"
  Launcher.new(options[:i18n_version],options[:threaded]).run
end
