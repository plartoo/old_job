require 'rubygems'
require 'active_record'
require 'yaml'
require 'ruby-debug'
require 'date'

l_sizes = YAML::load(File.open("brands.yml"))

id_max = 0
bm_max = 0
max_id = 0
id_list = []
bm_list = []
brand_name_list = []
l_sizes['data'].each{|x|
  max_id = x['id'] if x['id'] > max_id
  id_list.push(x['id'])
  if x['department_id'] == 4
    bm_max = x['bitmask_id'] if x['bitmask_id'] > bm_max
    bm_list.push(x['bitmask_id'])
    brand_name_list.push(x['name'])
  end
}
puts max_id
puts "#{id_list.sort.inspect}\n\n"
#puts "#{id_list.size}\n\n"
puts bm_max
puts "#{bm_list.sort.inspect}"
puts "#{bm_list.size}"
#puts "#{brand_name_list.sort.inspect}"
