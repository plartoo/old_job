require 'rubygems'
require 'ruby-debug'

# Usage: ruby dedupeBrands.rb <log_file_name>
# e.g., ruby dedupeBrands.rb Oli_uk_100419.log
# Description: this script will detect item descriptions
# that the fetcher framework can't extract/map brand names from
# and try to dedupe using a simple hash apporach

filename = ARGV[0]
f = File.open(filename,'r')
item_descriptions = []
f.each do |line|
  if line.match(%r#No Brand mapped#)
    item_descriptions.push line.match(%r#No Brand mapped\: (.*)#)[1]
  end
end

## simple deduping the brand names from item description
hash = {}
hoosh = {}

item_descriptions.each{|i|
  words = i.split(/\s/)
  hoosh[words.first] = words[1..-1].join(" ")
  hash[words.first] = hash.has_key?(words.first) ? 1 : 0
}

hash = hash.select{|k,v| v!=0}

hash.each{|k,v|
  puts k + " " + hoosh[k]
}
