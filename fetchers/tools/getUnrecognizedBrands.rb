require 'rubygems'
require 'ruby-debug'

resultFile = ARGV[0]
puts "\n\nProcessing,#{resultFile}\n\n"

# [2010-06-11 13:50:45.439] [INFO] INVALID ITEM=>
# [2010-06-11 13:50:45.439] [INFO] URL: /Shopping/ProductDetails.aspx?p=EC1211588&pg=5121230
# [2010-06-11 13:50:45.439] [INFO] because
# [2010-06-11 13:50:45.439] [INFO] 	No Brand recognized: Not Rated
# [2010-06-11 13:50:45.439] [INFO] 	No product image.
# [2010-06-11 13:50:45.439] [INFO] <=====================

a = {}
item_descriptions = []
url = nil
f = File.open(resultFile,'r').each{ |line|
  if line.match(%r"URL: (.*)\b")
    url = line.match(%r"URL: (.*)\b")[1]
  end
  m = line.match(%r#No Brand recognized: (.*)\b#) rescue nil
  if !m.nil?
    if !a.include?(m[1])
      a[m[1]] = [url]
    else
      a[m[1]].push url
    end
  end

  if line.match(%r#No Brand mapped#)
    item_descriptions.push line.match(%r#No Brand mapped\: (.*)#)[1]
  end

}
puts "Unknown Brands,#{a.keys.size}"
sum = 0
a.values.each{|arr|
  sum += arr.size
}
puts "Resulting items,#{sum}"
puts "=====\n"

a.sort{|x,y| x[1].size <=> y[1].size}.reverse.each{|arr|
  puts "#{arr.first},#{arr.last.size}"
}

## simple deduping the brand names from item description
hash = {}
hoosh = {}
puts "\n\nIf brands aren't explicit-the following is the list of possible brand names extracted from item descriptions"
puts "Don't panic if this list is empty--which means we don't have items with vague brands"
puts "=====\n"
item_descriptions.each{|i|
  words = i.split(/\s/)
  hoosh[words.first] = words[1..-1].join(" ")
  hash[words.first] = hash.has_key?(words.first) ? (hash[words.first]+1) : 1
}

hash.sort{|x,y| x[1] <=> y[1]}.reverse.each{|arr|
  puts arr[0].delete(",") + " " + hoosh[arr[0]].delete(",") + ",#{arr[1]}"
}
