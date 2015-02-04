require 'rubygems'
require 'active_record'
require 'yaml'
require 'ruby-debug'
require 'date'

class Hash
  # Replacing the to_yaml function so it'll serialize hashes sorted (by their keys)
  #
  # Original function is in /usr/lib/ruby/1.8/yaml/rubytypes.rb
  def to_yaml( opts = {} )
    YAML::quick_emit( object_id, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
        main_keys = %w(name auto_increment_key unique_keys dynamic_keys data)
        brand_keys = %w(id name display_name bitmask_id department_id parent_id created_at)
        if self.keys.to_set == brand_keys.to_set
          sort{|a,b| brand_keys.index(a[0]) <=> brand_keys.index(b[0])}.each do |k,v|
            map.add(k,v)
          end
        elsif self.keys.to_set == main_keys.to_set
          sort{|a,b| main_keys.index(a[0]) <=> main_keys.index(b[0])}.each do |k,v|
            map.add(k,v)
          end
        else
          sort.each do |k, v|   # <-- here's my addition (the 'sort')
            map.add( k, v )
          end
        end
      end
    end
  end
end

#h = { :data => [{"id" => '1', "name" => 'phyo', 'age' => '25'},
#     {"id" => '2', "name" => 'phyo1', 'age' => '26'},
#     {"id" => '3', "name" => 'phyo2', 'age' => '27'}]
#}
#
#puts h.to_yaml


# local brands
l_brands = YAML::load(File.open("brands_orig.yml"))

count = 0
l_brands['data'].each{|x|
  if x['created_at'].blank?
    x['created_at'] = DateTime.new(2009,02,12, 00,00).strftime("%Y-%m-%d %H:%M:%S -00:00")
    #count+= 1
  end
}
File.open('brands.yml','w') do |f|
  f.puts l_brands.to_yaml
end
puts count



#ActiveRecord::Base.establish_connection(
#:adapter=> "mysql",
#:host => "localhost",
#:database=> "sitm_development_uk"
#)
#
#class Brands < ActiveRecord::Base
#end
#count = 0
#j_brands = Brands.find(:all)
#j_brands.each{|x|
#  if x['created_at']
#    count+= 1
#  end
#}
#
#puts count

#similarity_count = 0
#disimilarity = 0
#j_brands.each{|x| # each x will be a Brands object
#  l_brands.each{|y|
#    if (x.id == y['id']) && (x.bitmask_id == y['bitmask_id']) && (x.parent_id == y['parent_id']) # && (x.display_name == y['display_name']) && (x.name == y['name'])
#      similarity_count += 1
#    #elsif (x.id == y['id'])
#    #  puts "#{x.inspect}\n#{y.inspect}\n==========="
#    #  disimilarity += 1
#    end
#    #if (x.created_at == y['created_at'])
#    #  disimilarity += 1
#    #end
#  }
#}
#
#puts similarity_count
#puts disimilarity



#File.open('brands.yml','w') do |f| 
#  f.puts Brands.find(:all).to_yaml
#end
#Brands.find(:all).to_yaml#each{|x| puts x.created_at}