require 'rubygems'
require 'yaml'

types = YAML::load_file('config/common/common_clothing_types.yml')
keys = types.keys
lines = 0
File.open(ARGV[0]).each do |line|
	cur_clth = line.match(/clothing_type\: \:(.*)/)[1] rescue ''
	cur_clth = cur_clth.to_sym rescue ''
	lines += 1
	if !keys.include?(cur_clth)
		puts "#{lines}: #{cur_clth}" if cur_clth != ""
	end
end

