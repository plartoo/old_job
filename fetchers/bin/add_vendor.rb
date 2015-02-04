#!/usr/bin/env ruby

# adds the vendor name to the yaml item feed file by using the path name of the file
# the vendor name is required for importing the item into the apparel_search_items table

# usage add_vendor.rb <yaml_feed>  <yaml_feed> ...

require 'yaml'
require 'rubygems'

item_feed_files = ARGV

item_feed_files.each do |y|
  items = YAML::load_file(y)
  vendor_name = File.split(File.dirname(y)).last
  items.each do |item|
    item[:vendor_name] ||= vendor_name
  end
  File.open(y,"w") do |f|
    f.write(YAML::dump(items))
  end
end
