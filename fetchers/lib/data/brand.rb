require 'brand_mapper'
require 'department'
require 'yaml'
require 'active_record'
require 'open-uri'

class Brand < Base # :nodoc:
  
  @@config_dir = File.join(Configuration.config_dir, "..", "common", "brands")
  @@brands = {}


  def self.get_brand_name(dept, brand_key)
    brands = brands_from_yml_file(brand_file(dept))
    brands.select{|x| x['id']==brand_key}.first['name']
  end
  
  def self.get_best_matching_brand_bm(dept, value)
    unless @@brands[dept]
      load_brand_mapper(dept)
    end
    @@brands[dept].get_best_matching_brand(clean_value(value))
  end

  def self.clean_value(value)
    value.sub(/&amp;/, '&').downcase
  end
  
  def self.brand_file(dept)
    File.join(@@config_dir, "#{dept.to_s.downcase}_brands.yml")
  end
  
  def self.config_dir
  @@config_dir
  end

  def self.config_dir=(config_dir)
    @@config_dir = config_dir
  end

  def self.load_brand_mapper(dept)
    brands = brands_from_yml_file(brand_file(dept))
    add_brands_to_mapper(dept,brands)
    load_additional_brand_mappings(dept)
  end
  
  def self.load_additional_brand_mappings(dept)
    brands = brands_from_yml_file(File.join(self.config_dir, "mappings", "#{dept.to_s.downcase}_brand_mappings.yml"))
    add_brands_to_mapper(dept,brands)
  end
  
  def self.brands_from_yml_file(file)
    YAML.load_file(file)
  rescue Errno::ENOENT
    []
  end
  
  def self.add_brands_to_mapper(dept, brands)
    @@brands[dept] ||= BrandMapper.new
    brands.each do |brand|
      @@brands[dept].add_brand(brand["name"].downcase, brand["id"])
    end
  end

  def self.generate_brands_yml(i18n_version = :us)
    connect_active_record(i18n_version)
    Department.all.delete_if{|x| x.to_s =~ /running/}.each do |dept|
      brands = YAML.load(URI.parse("http://127.0.0.1:3000/admin/brand/non_hidden_brand_list/#{dept.to_s.upcase}").read)
      unless brands.empty?
        File.open(brand_file(dept), "wb") do |f|
          f.write brands.to_yaml
        end
      end
    end
  end

end
