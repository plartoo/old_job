require File.dirname(__FILE__) + '/../base'
require 'yaml'
require 'active_record'


class Size < Base # :nodoc:
  class Size < ActiveRecord::Base
    belongs_to :size_type
  end
  class SizeType < ActiveRecord::Base
    has_many :sizes
  end

  @@sizes = {}

  class SizeException < Exception
  end
  
  class InvalidSizeException < SizeException
  end

  SIZE_MAPPINGS = {
    'petite' => 'PETITE',
    'extra small' => 'XS',
    'xsmall' => 'XS',
    'x-small' => 'XS',
    'xx-small' => 'XXS',
    'xxsmall' => 'XXS',
    'small' => 'S',
    'medium' => 'M',
    'large' => 'L',
    'extra large' => 'XL',
    'xlarge' => 'XL',
    'x-large' => 'XL',
    'xxlarge' => 'XXL',
    'xx-large' => 'XXL',
    'xs/s' => ['XS', 'S'],
    's/m' => ['S', 'M'],
    'm/l' => ['M', 'L'],
    'l/xl' => ['L', 'XL'],
    'xxs' => 'XXS',
    'xs' => 'XS',
    's' => 'S',
    'm' => 'M',
    'l' => 'L',
    'xl' => 'XL',
    'xxl' => 'XXL'
  }

  def self.config_dir
    @@config_dir ||= File.join(Configuration.config_dir, "sizes")
  end
  
  def self.size_types
    @@size_types ||= YAML.load_file(File.join(self.config_dir, 'size_types.yml'))
  end

  def self.size_map(value)
    SIZE_MAPPINGS[value.downcase] || value
  end

  def self.get_size(fetcher_class,value_str, item)
    sizes = []
    values = size_map(value_str)
    values = values.is_a?(Array) ? values : [values]
    values.each do |value|
      unless @@sizes[item.dept] && @@sizes[item.dept][item.clothing_type[:group]]
        load_dept_group(item)
      end

      bm = get_size_bm(value, item)
      type_bm = get_size_type_bm(item)

      if bm.nil? || type_bm.nil?
        fetcher_class.log.error "INVALID SIZE: value: #{value} is not a valid size for dept: #{item.dept}, clothing_type: #{item.clothing_type.inspect} \n URL: #{item.product_url}"
        raise InvalidSizeException
      end
      sizes << {:bm => bm, :type_bm => type_bm}
    end
    sizes
    
  end

  def self.load_dept_group(item)
    @@sizes[item.dept] ||= {}
    @@sizes[item.dept][item.clothing_type[:group]] = load_dept_group_sizes(item)
  end

  def self.load_dept_group_sizes(item)
    dept = item.dept
    group = item.clothing_type[:group]
    if dept == :boys || dept == :girls
      if group == :shoe
        return YAML.load_file(File.join(self.config_dir, "#{dept.to_s}_shoes.yml"))
      else
        return YAML.load_file(File.join(self.config_dir, "#{dept.to_s}_sizes.yml"))
      end
    elsif dept.to_s.match(/running/)
      return YAML.load_file(File.join(self.config_dir, "activewear_sizes.yml"))
    else
      if group.to_s.match(/s$/)
        return YAML.load_file(File.join(self.config_dir, "#{dept.to_s}_#{group.to_s}_sizes.yml"))
      else
        return YAML.load_file(File.join(self.config_dir, "#{dept.to_s}_#{group.to_s}s_sizes.yml"))
      end
    end
  end

  def self.get_size_bm(string, item)
    if size = self.find_size(string, item)
      return size
    end
    if size = self.find_size_by_synonym(string, item)
      return size
    end

    if item.clothing_type[:group] == :accessories
      return @@sizes[item.dept][item.clothing_type[:group]].select{|x| x[:name] == "ALL_SIZES"}.first[:bitmask_id]
    end
  end

  def self.find_size(size, item)
    @@sizes[item.dept][item.clothing_type[:group]].each do |data|
      if size == data[:name]
        return data[:bitmask_id]
      end
    end
    nil
  end
  
  def self.find_size_by_synonym(size, item)
    dept = item.dept
    group = item.clothing_type[:group]
    if self.respond_to?("synonym_within_#{dept}_#{group}") && group
      return self.find_size(self.send("synonym_within_#{dept}_#{group}", size), item)
    end
    if self.respond_to?("synonym_within_#{group}") && group
      return self.find_size(self.send("synonym_within_#{group}", size), item)
    end    
    if self.respond_to?("synonym_within_#{dept}")
      return self.find_size(self.send("synonym_within_#{dept}", size), item)
    end
  end
  
  def self.synonym_within_shoe(size)
    size.gsub(/ /,'').gsub(/AA/,'B').gsub(/D/,'')
  end
  
  def self.synonym_within_mens_top(size)
    if size.match(/-/)
      size.gsub("-", " ")
    elsif match = size.match(/(\d+)R/)
      match[1]
    end
  end
    
  def self.synonym_within_boys_intimate(size)
    raise InvalidSizeException
  end
  
  def self.synonym_within_girls_intimate(size)
    raise InvalidSizeException
  end
  
  def self.synonym_within_boys(size)
    size + "T"
  end
  
  def self.synonym_within_girls(size)
    size + "T"
  end

  def self.synonym_within_womens_top(size)
    if size.match(/PLUS/)
      return size.gsub(/PLUS/, "PLUS1X")
    end
  end
  
  def self.synonym_within_womens_bottom(size)
    if size.match(/PLUS/)
      return size.gsub(/PLUS/, "PLUS1X")
    end
    if match = size.match(/^(\d+)$/)
      return size + "R"
    end
    if match = size.match(/(\d+)[X|x](\d+)/)
      waist = match[1]
      inseam = match[2]
      
      unless %w(24 25 26 27 28 29 30 31 32).include?(waist) || waist.to_i < 24
        unless %w(33X34 34X34).include?(size)
          raise InvalidSizeException
        end
      end
      
      if inseam == "30"
        if waist.to_i >= 24
          waist + "R"
        else
          waist
        end
      elsif inseam == "32" || inseam == "34"
        waist + "L"
      end
    end
  end

  def self.get_size_type_bm(item)
    dept = item.dept
    group = item.clothing_type[:group]
    if dept == :boys || dept == :girls
      if group.eql?(:shoe)
        return self.size_types["#{dept.to_s}_shoes".to_sym]
      else
        return self.size_types["#{dept.to_s}_sizes".to_sym]
      end
    else
      return self.size_types["#{dept.to_s}_#{group.to_s}".to_sym]
    end
  end
  
  def self.generate_sizes_yml(application = :us)
    connect_active_record(application)
    SizeType.all.each do |size_type|
      if size_type.name.match(/^(BOYS|GIRLS)/)
        filename = File.join(self.config_dir, "/#{size_type.name.downcase}.yml")
      else
        filename = File.join(self.config_dir, "/#{size_type.name.downcase}_sizes.yml")
      end
      File.open(filename, "w") do |f|
        YAML.dump(size_type.sizes.map{|x| {:name => x.name, :bitmask_id => x.bitmask_id}}, f)
      end
    end
  end
  

end
