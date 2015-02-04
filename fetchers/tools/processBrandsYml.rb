require 'rubygems'
require 'active_record'
require 'yaml'
require 'ruby-debug'
require 'date'

l_sizes = YAML::load(File.open("brands.yml"))

id_max = 0

# for selecting mens bottom sizes
# such as 26X26 etc
bm_max = 0
max_id = 0
id_list = []
bm_list = []
size_name_list = []
l_sizes['data'].each{|x|
  max_id = x['id'] if x['id'] > max_id
  id_list.push(x['id'])
  if x['department_id'] == 1
    bm_max = x['bitmask_id'] if x['bitmask_id'] > bm_max
    bm_list.push(x['bitmask_id'])
    size_name_list.push(x['name'])
  end
}
puts "max id: \n#{max_id}"
#puts "#{id_list.sort.inspect}\n\n"
puts "total id list size: \n#{id_list.size}\n\n"
puts "bit mask max: \n#{bm_max}\n\n"
puts "bit mask list: \n#{bm_list.sort.inspect}\n\n"
puts "bit mask list size: \n#{bm_list.size}\n\n"
#puts "#{((1..65).to_a - bm_list.sort).inspect}\n\n"
#puts "#{size_name_list.sort.inspect}"




## finding max id
#l_sizes['data'].each{|x|
#  id_max = x['id'] if x['id'] > id_max
#}
#puts id_max

## finding max bitmask id
#bm_max = 0
#
#l_sizes['data'].each{|x|
#  if x['size_type_id'] == 10
#    bm_max = x['bitmask_id'] if x['bitmask_id'] > bm_max
#  end
#}
#puts bm_max

