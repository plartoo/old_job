require 'rubygems'
require 'ruby-debug'
require 'time'

log_file = ARGV[0]
puts "\n\nProcessing #{log_file}\n\n"

def get_timing(seconds)
  "#{(seconds/3600).floor}:#{((seconds%3600)/60).floor}:#{seconds%60}"
end

fetchers = {}

file = File.open(log_file,"r")
line = file.readline
#lines = 0
begin
  while line
    #lines += 1
    #puts lines if lines % 100000 == 0

    if line.match(/\[([\w_]+)\] result: Total of item and scc scraping: (.*)/)
      fetcher,total = line.match(/\[([\w_]+)\] result: Total of item and scc scraping: (.*)/)[1,2]
    elsif line.match(/\[([\w_]+)\] result: category_scrapers: (.*)/)
      fetcher,categories = line.match(/\[([\w_]+)\] result: category_scrapers: (.*)/)[1,2]
    elsif line.match(/\[([\w_]+)\] result: sccs_scrapers: (.*)/)
      fetcher,sccs_scrapers = line.match(/\[([\w_]+)\] result: sccs_scrapers: (.*)/)[1,2]
    elsif line.match(/\[([\w_]+)\] result: item_scrapers: (.*)/)
      fetcher,item_scrapers = line.match(/\[([\w_]+)\] result: item_scrapers: (.*)/)[1,2]
    end
    
    if fetcher && (total || categories || sccs_scrapers || item_scrapers)
      fetchers[fetcher] = {} if !fetchers[fetcher]
      (fetchers[fetcher][:total] = total) && (total = nil) if total
      (fetchers[fetcher][:categories] = categories) && (categories = nil) if categories
      (fetchers[fetcher][:item_scrapers] = item_scrapers) && (item_scrapers = nil) if item_scrapers
      (fetchers[fetcher][:sccs_scrapers] = sccs_scrapers) && (sccs_scrapers = nil) if sccs_scrapers
      fetcher = nil
    end

    
    line = file.readline
  end
rescue EOFError
  nil
end

puts "Fetcher\tTotal\tCat\tItemScrape\tSccs"
fetchers.keys.sort.each do |fetcher|
  str = "#{fetcher}\t"
  data = fetchers[fetcher]
  str += "#{data[:total]}\t"
  str += "#{data[:categories]}\t"
  str += "#{data[:item_scrapers]}\t"
  str += "#{data[:sccs_scrapers]}\t"
  puts "#{str}"
end

