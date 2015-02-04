$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'yaml'
require 'item'
require 'set'
require 'pp'
require 'logger'

vendor = ARGV[0] || 'katespade'
date = ARGV[1] || Date.today.strftime("%y%m%d")

log_file = File.join(File.dirname(__FILE__), 'log')
unless File.exist?(log_file)
  FileUtils.mkdir_p(log_file)
end
log_file = File.open(File.join(log_file, "diff_#{date}.log"), "a+")
log = Logger.new(log_file)

ruby_items = YAML.load_file(File.expand_path(File.dirname(__FILE__) + "/yaml_feeds/#{vendor}/#{date}.yml"))
java_items = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'sitm-java', 'yaml_feeds', vendor, "#{date}.yml")))

sorter = lambda do |a, b|
  result = a[:description] <=> b[:description]
  if result == 0
    if a[:scc].nil?
      pp a
    elsif b[:scc].nil?
      pp b
    end
    result = a[:scc].size <=> b[:scc].size
  end
  result
end

ruby_items = ruby_items.sort(&sorter).map do |item_hash|
  Item.load_from_hash(item_hash)
end

java_items = java_items.sort(&sorter).map do |item_hash|
  Item.load_from_hash(item_hash)
end

log.info("found #{ruby_items.size} ruby items and #{java_items.size} java items")

extra_ruby_items = []
pairs = []
ruby_items.each do |ruby_item|
  java_item = nil
  java_items.each do |i|
    if i == ruby_item
      java_item = i
      java_items.delete(i)
      break
    end
  end

  if java_item.nil?
    extra_ruby_items << ruby_item
  else
    pairs << [ruby_item, java_item]
  end
end

log.info("checking #{vendor}")

item_logger = lambda do |item|
  log.error(item.to_yaml)
end

if extra_ruby_items.size > 0
  log.error("found #{extra_ruby_items.size} item(s) in ruby fetch that were not in java fetch")
  extra_ruby_items.each(&item_logger)
end

if java_items.size > 0
  log.error("found #{java_items.size} item(s) in java fetch that were not in ruby fetch")
  java_items.each(&item_logger)
end

log.close
