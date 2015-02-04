require 'rubygems'
require 'time'
require 'ruby-debug'
class String
   def underscore
       self.gsub(/::/, '/').
       gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       tr("-", "_").
       downcase
   end
end

def choose_the_right_key(hash, vendor_name)
  v_for_vendetta = vendor_name.match(/.*_(\w+)$/)[1] rescue vendor_name
  hash.keys.select{|x| x.match(/#{v_for_vendetta}/i)}.first rescue vendor_name
end

def find_end_time(lines)
  pivot = -1
  end_time = Time.parse(lines[pivot].match(TIME)[1]) rescue nil

  while (end_time.nil? && ((pivot*-1) < lines.size))
    pivot += -1
    end_time = Time.parse(lines[pivot].match(TIME)[1]) rescue nil
  end
  end_time
end

LOG_FILE_LOC = File.join(File.dirname(__FILE__), 'log')
YML_FILE_LOC = File.join(File.dirname(__FILE__), 'yaml_feeds')
VENDOR_NAME_FROM_YML = /.*\/(.*?)\/\d+\.yml/
VENDOR_NAME_FROM_LOG = /log\/(.*?)_u(k|s)\.log/
TIME = /\[(.*?)\]/

yamls = Dir.glob(YML_FILE_LOC+"/us/*/*")
logs = Dir.glob(LOG_FILE_LOC+"/*").reject{|x| x.match(/launcher\.log/)}

results = {}
yamls.each do |yml_file|
  vendor = yml_file.match(VENDOR_NAME_FROM_YML)[1]
  size = YAML.load(File.open(yml_file,'r')).size rescue 0
  results[vendor] = [size]
end

logs.each do |log_file|
  vendor = log_file.match(VENDOR_NAME_FROM_LOG)[1].underscore
  lines = IO.readlines(log_file)
  start_time = Time.parse(lines.first.match(TIME)[1]) rescue nil
  end_time = find_end_time(lines)

  if start_time && end_time
    time_taken = (end_time - start_time)/60
  else
    time_taken = 'na'
  end
  vandor = choose_the_right_key(results, vendor)
  results[vandor].push time_taken
end


results.each do |k,v|
  puts "#{k},#{v.first},#{v.last}"
end
