require 'rubygems'
require 'active_record'
require 'yaml'
require 'ruby-debug'
require 'date'

l_sizes = YAML::load(File.open("sizesSitm.yml"))
l_sizes = YAML::load(File.open("sizesSitm.yml"))

id_max = 0

bm_max = 0
max_id = 0
id_list = []
bm_list = []
size_name_list = []
l_sizes['data'].each{|x|
  max_id = x['id'] if x['id'] > max_id
  id_list.push(x['id'])
  if x['size_type_id'] == 7 #&& x['selector'] =~ /neck/
    bm_max = x['bitmask_id'] if x['bitmask_id'] > bm_max
    bm_list.push(x['bitmask_id'])
    size_name_list.push(x['name'])
  end
}
puts max_id
puts "#{id_list.sort.inspect}\n\n"
puts "#{id_list.size}\n\n"
puts bm_max
puts "#{bm_list.sort.inspect}"
puts "#{bm_list.size}"
puts "#{((0..92).to_a - bm_list.sort).inspect}\n\n"
puts "#{size_name_list.sort.inspect}"

neck = ['14','14.5','15','15.5','16','16.5','17','17.5','18','18.5']
sleeve = ['32/33','34/35','36/37','38/39']

expected = []
neck.each do |n|
  sleeve.each do |s|
    expected.push(n+' '+s)
  end
end

puts "#{expected.inspect}\n==========\n"
puts "#{(expected - size_name_list).sort.inspect}"

