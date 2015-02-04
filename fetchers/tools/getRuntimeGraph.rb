START = /(.{30}): \[\d+\] Starting ([a-z_]+)$/
FINISH = /(.{30}): \[\d+\] Completed ([a-z_]+)/
ITEMS = /\[([a-z_]+)\] result: Number of items with successful SCCS scraping: (\d+) out of (\d+) valid items\./
IMPORT_START = /(.{30}): \[\d+\] Importing ([a-z_]+)$/
IMPORT_FINISH = /(.{30}): \[\d+\] Importing finished: ([a-z_]+)/
LOWEST_TIME_OBJECT = Time.at(0)
ONE_SECOND_TIME_STRING = Time.at(1).to_s
RUNNING_ICON = "X"
IDLE_ICON = " "
IMPORT_ICON = "-"

require 'rubygems'
require 'optparse'
require 'time'

def increment_grid(grid,offset,run_duration,before_import_offset,import_duration)
  run_duration.times do |n|
    grid[offset+n][:run] += 1
  end
  import_duration.times do |n|
    grid[offset+run_duration+before_import_offset+n][:import] += 1
  end
end

def timefmt(time_as_int)
  Time.at(time_as_int).strftime("%H:%M:%S") rescue "UNKN"
end

options = {}
opts = OptionParser.new do |opts|
  opts.banner = "Usage: ruby getRuntimeGraph.rb -l log_file <-s scale_in_mins> <-b begin_date> <-e end_time>\n\n"
  # Mandatory argument.
  opts.on("-l LOG_FILE", "--log LOG_FILE",
          "Use this log file.") do |log|
    options[:log] = log
  end

  #optional arguments
  opts.on("-a LOG_FILE", "--add LOG_FILE",
          "Additional log file to use BEFORE parsing -l log file.  Useful when tracking across multiple log files.") do |log|
    options[:additional_log_file] = log
  end

  opts.on("-s N","--scale N", Integer, "Scale to use for the graph") do |n|
    options[:scale] = n
  end

  opts.on("-b TIME","--begin TIME", String, "Begin parsing at a given time") do |time|
    options[:start_time] = Time.parse(time)
  end

  opts.on("-e TIME","--end TIME", String, "End parsing at a given time") do |time|
    options[:end_time] = Time.parse(time)
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end


end
opts.parse!(ARGV)

if !options[:log] || !File.exist?(options[:log])
  puts "Log file param is needed, and must exist!"
  puts opts
  exit
end

min_scale = options[:scale].to_i > 0 ? options[:scale].to_i : 15
start_time = options[:start_time] ? options[:start_time] : LOWEST_TIME_OBJECT
end_time = options[:end_time] ? options[:end_time] : Time.now


puts "Processing #{options[:log]} on a #{min_scale} minute scale\nStarting at #{start_time}, ending at #{end_time}\n\n"
#num_lines = (`wc -l #{options[:log]}`).match(/(\d+)/)[1].to_i
#puts "0          100"
#ten_percent = (num_lines*0.1).floor
seconds_scale = min_scale  * 60

fetchers = {}

GREP_REGEX_MATCH_FOR_DESIRED_LINES = "(Starting|Completed|Import|Number of items with successful)"

def process_lines(lines,fetchers,start_time,end_time)
  lines.each_with_index do |line,index|
    #print '.' if index % ten_percent == 0

    log_time_object = Time.parse(line.match(/(.{30}): \[/)[1]) rescue nil
    next unless log_time_object && log_time_object > start_time

    if line =~ START
      line.scan(START).each do |time,fetcher|
        fetchers[fetcher] ||= {:start => Time.parse(time).to_i}
      end
    end

    if line =~ FINISH
      line.scan(FINISH).each do |time,fetcher|
        fetchers[fetcher] ||= {:start => Time.parse(time).to_i}
        fetchers[fetcher][:finish] ||= Time.parse(time).to_i
      end
    end

    if line =~ ITEMS
      line.scan(ITEMS).each do |fetcher,items_got,items_total|
        fetchers[fetcher] ||= {:start => Time.parse(time).to_i}
        fetchers[fetcher][:items_got] ||= items_got
        fetchers[fetcher][:items_total] ||= items_total
      end
    end

    if line =~ IMPORT_START
      line.scan(IMPORT_START).each do |time,fetcher|
        fetchers[fetcher] ||= {:start => Time.parse(time).to_i}
        fetchers[fetcher][:importer_start] ||= Time.parse(time).to_i
      end
    end
    
    if line =~ IMPORT_FINISH
      line.scan(IMPORT_FINISH).each do |time,fetcher|
        fetchers[fetcher] ||= {:start => Time.parse(time).to_i}
        fetchers[fetcher][:importer_finish] ||= Time.parse(time).to_i
      end
    end

    if log_time_object
      break if log_time_object > end_time
    end
  end
end

if options[:additional_log_file]
  lines = `grep -E "#{GREP_REGEX_MATCH_FOR_DESIRED_LINES}" #{options[:additional_log_file]}`
  process_lines(lines,fetchers,start_time,end_time)
end

lines = `grep -E "#{GREP_REGEX_MATCH_FOR_DESIRED_LINES}" #{options[:log]}`
process_lines(lines,fetchers,start_time,end_time)

fetchers.each do |fetcher,data|
  fetchers[fetcher][:importer_start] ||= data[:finish]
end

fetchers = fetchers.sort_by{|key,val| val[:start]}
first_start = fetchers.first.last[:start]
begin
  last_finish = fetchers.sort_by{|key,val| val.values.max}.last.last.values.max
rescue NoMethodError => e
  puts "\n\nAre you sure fetchers are done running, or your time range is correct? Some data is missing."
  raise e, e.message
end
num_frames = (((last_finish - first_start) / seconds_scale.to_f)+1).ceil
longest_fetcher_name_size = fetchers.sort_by{|key,val| key.size}.last.first.size

total_duration_sum = 0
fetchers.each do |fetcher,data|
  total_duration_sum += data[:finish] - data[:start]
end

puts "Total runtime: #{(last_finish - first_start) / 60} mins"
puts "Sum of all fetcher's runtime: #{total_duration_sum / 60} mins"
puts "Legend:\n\tIdle: \"#{IDLE_ICON}\"\n\tRunning: \"#{RUNNING_ICON}\"\n\tImporting: \"#{IMPORT_ICON}\""
grid = Array.new(num_frames)
grid.map!{|x| {:run => 0,:import => 0}}

fetchers.each do |fetcher,fetcher_data|
  fetcher_name = "#{fetcher}#{Array.new(longest_fetcher_name_size - fetcher.size," ")}"
  begin
    slots_offset = ((fetcher_data[:start] - first_start) / seconds_scale.to_f).floor
    fetching_duration = fetcher_data[:finish] - fetcher_data[:start]
    slots_fetching = [1,(fetching_duration / seconds_scale.to_f).ceil].max

    before_import_offset = ((fetcher_data[:importer_start] - fetcher_data[:finish]) / seconds_scale.to_f).floor
    importing_duration = fetcher_data[:importer_finish] - fetcher_data[:importer_start]
    slots_importing = [1,(importing_duration / seconds_scale.to_f).ceil].max

    end_offset = [0,(num_frames - slots_offset - slots_fetching - before_import_offset - slots_importing)].max
    increment_grid(grid,slots_offset,slots_fetching,before_import_offset,slots_importing)
    graph = [IDLE_ICON*slots_offset,RUNNING_ICON*slots_fetching,IDLE_ICON*before_import_offset,IMPORT_ICON*slots_importing,IDLE_ICON*end_offset].to_s
    comment = "#{fetching_duration/60} mins run, #{importing_duration/60} mins importing. #{timefmt(fetcher_data[:start])} - #{timefmt(fetcher_data[:importer_finish])}"
    puts "#{fetcher_name}:#{graph}: #{comment}"
  rescue => e
    puts "#{fetcher_name}:error occured calculating graph for this retailer"
  end
end
concurrent_count =  grid.sort_by{|x| x[:run]}.last[:run]
puts "\nConcurrently running fetcher count (#{concurrent_count} max):"
concurrent_count.downto(1) do |row|
  (longest_fetcher_name_size - row.to_s.size).times{print " "}
  print "#{row}:"
  num_frames.times do |col|
    if grid[col][:run] >= row
      print RUNNING_ICON
    elsif grid[col][:import] + grid[col][:run] >= row
      print IMPORT_ICON
    else
      print IDLE_ICON
    end
  end
  print ":\n"
end

last_fetcher_banner =  "* last fetchers *"
puts "*" * last_fetcher_banner.length
puts last_fetcher_banner
puts "*" * last_fetcher_banner.length

fetchers.sort_by{|key,val| -(val[:importer_start] || val[:finish]) }[0..5].each do |fetcher_name, fetcher_data|
  puts "#{timefmt(fetcher_data[:importer_start])} (#{timefmt(fetcher_data[:start])}): #{fetcher_name}"
end


