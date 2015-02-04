require 'rubygems'
require 'ruby-debug'

resultFile = ARGV[0]
puts "\n\nProcessing #{resultFile}\n\n"

#TOTAL ITEM COUNT(For current fetcher)::::1064
#item_scraper.rb: url-> http://www.saksfifthavenue.com/main/ProductArray.jsp?FOLDER%3C%3Efolder_id=2534374306418079&ASSORTMENT%3C%3East_id=1408474395222441&bmUID=1259146972566&use_parent=1&SECSLOT=LN-Boots&display=10000&ShowPage=7
#BRANDS UNRECOGNIZED:Veronique Branquinho
#====INVALID ITEM=====
#<Item:0x50dfea8

a = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
url = nil

f = File.open(resultFile,'r').each{ |line|
  if line =~ /^BRANDS UNRECOGNIZED:/
    m = /^BRANDS UNRECOGNIZED:(.*)/.match(line)
    if !m.nil? && !a.has_key?(m[1])
      a[m[1]] = 1
    end
  end
}
a = a.sort
a.each{|i|
  puts i[0]
}
