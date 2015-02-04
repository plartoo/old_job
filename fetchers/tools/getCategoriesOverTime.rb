### Writes out to STDOUT a csv:
#     ,date, date, date
# cat1, num,  num,  num
# cat2, num,  num,  num
# cat3, num,  num,  num
#
# where cat# is a clothing type, num is aggregated over fetchers passed in
#

require 'rubygems'
require 'optparse'
require 'time'

class NoFetchersSelected < StandardError; end
class NoDatesSelected < StandardError; end

def files_for(path,date)
  Dir.entries(path).select{|f| f =~ /#{date}/}
end
def process_file(file,date,categories)
  if file !~ /\.gz$/
    File.open(file,"r").each do |line|
      process_line(line,date,categories)
    end
  else
    # try if it's gzipped
    lines = `zcat #{file}`
    lines.each do |line|
      process_line(line,date,categories)
    end
  end
end
CLOTHING_TYPE_LINE = /:clothing_type_bm: (\d+)/
def process_line(line,date,categories)
  if line =~ CLOTHING_TYPE_LINE
    clothing_type = line.match(CLOTHING_TYPE_LINE)[1]
    categories[clothing_type.to_i] ||= {}
    categories[clothing_type.to_i][date] ||= 0
    categories[clothing_type.to_i][date] += 1
  end
end
def print_final_counts(categories)
  totals = {}
  categories.each do |clothing_type_bm,data|
    data.each do |date,total|
      totals[date] ||= 0
      totals[date] += total
    end
  end
  to_print = ['Totals']
  totals.keys.sort.each do |date|
    to_print << totals[date]
  end
  puts to_print.join(',')
end

options = {:fetchers => [], :dates => [], :clothing_types_file => "config/common/common_clothing_types.yml"}
opts = OptionParser.new do |opts|
  opts.banner = "Usage: ruby getCategoriesOverTime -f fetcher -d date \n\n"
  # Mandatory argument.
  opts.on("-f FETCHER_PATH", "--fetcer FETCHER_PATH", "Use this fetcher path for aggregation (can be used more than once).") do |f|
    options[:fetchers] << f
  end
  # Mandatory argument.
  opts.on("-d DATE", "--date DATE", "YYMMDD date to use (can be used more than once).") do |f|
    options[:dates] << f
  end
  # Mandatory argument.
  opts.on("-p YAML_FEED_PATH", "--path YAML_FEED_PATH", "Path to the yaml_feeds folder.") do |f|
    options[:path] = f
  end

  opts.on("-c CLOTHING_TYPES_FILE", "--clothing_types CLOTHING_TYPES_FILE", "Path to the clothing_types yaml file. default: #{options[:clothing_types_file]}.") do |f|
    options[:clothing_types_file] = f
  end
end
opts.parse!(ARGV)

raise NoFetchersSelected unless options[:fetchers].any?
raise NoDatesSelected unless options[:dates].any?
raise NoYamlPathSelected unless options[:path]

common_clothing_type_data = YAML::load_file(options[:clothing_types_file])
common_clothing_types = {}
common_clothing_type_data.each do |name,data|
  common_clothing_types[data[:bm]] = name
end

files = {}
options[:dates].each do |date|
  files[date] = []

  options[:fetchers].each do |fetcher_path|
    path = options[:path] + "/"+fetcher_path
    files_for(path,date).each do |file|
      files[date] << path + "/" + file
    end
  end
end

options[:dates] = options[:dates].sort.reverse

puts "categories,"+options[:dates].map{|x| Time.parse(x).strftime("%b-%d-%Y")}.join(',')

categories = {}
files.each do |date,yaml_files|
  yaml_files.each do |fetcher_yaml|
    process_file(fetcher_yaml,date,categories)
  end
end

categories.each do |clothing_type_bm,data|
  to_print = [common_clothing_types[clothing_type_bm]]
  options[:dates].each do |date|
    to_print << data[date] || 0
  end
  puts to_print.join(',')
end

print_final_counts(categories)

puts "Fetchers chosen:"
options[:fetchers].each do |fetcher|
  puts ","+fetcher
end
