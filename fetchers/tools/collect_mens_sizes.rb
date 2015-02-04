require 'rubygems'
require 'ruby-debug'

feed_dir = "/usr/local/salemail/yaml_feeds/"
mens_sizes_file = "/usr/local/fetchers/current/config/us/sizes/mens_tops_sizes.yml"
mens_sizes = YAML.load_file(mens_sizes_file)
h = mens_sizes.inject({}){|h,e| 
	h[e[:bitmask_id]]=e[:name]
	h
}

yaml_files = Dir.glob(File.join(feed_dir+"*/*")).reject do |f|
   !f.match(/101130\.yml/) rescue next
end

sizes = {}
yaml_files.each do |f|
   items = YAML.load_file(f)
   items = items.select{|x| x[:dept].eql?(:mens)} rescue []
   items.each do |men_item|
	men_items = men_item[:scc].select{|x| x[:size_type_bm].eql?(1)} rescue []
	men_items.each do |men_tops|
		sizes[men_tops[:size_bm]] ||= 0
		sizes[men_tops[:size_bm]] += 1
	end
   end
end


sizes.sort_by{|k,v| k}.each do |size,count|
  puts "#{h[size]},#{count}"
end
debugger
1

