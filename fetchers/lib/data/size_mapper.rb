class SizeMapper # :nodoc:
  attr_accessor :mappers

  class Mapper
    attr_accessor :mapper
  end

  def initialize(fetcher_class)
    @fetcher_class = fetcher_class
    @mappers = []
  end

  # ==Run size through a mapper and return an array of matching sizes
  # Useful for:
  # * Converting form US to UK sizes
  # * Cleaning funny retailer specific characters from sizes
  def map(size, item)
    size = size.strip unless size.nil?
    matches = [size]
    method_name = self.method_name_from_item(item)
    self.mappers.each do |mapper|
      if mapper.respond_to?(method_name)
        match = mapper.send(method_name, matches.last, item)
        matches << match unless match.nil?
      end
    end
    matches.last.is_a?(Array) ? matches.last : [matches.last]
  end

  # ==accepts mapper as a hash or a module with methods defined
  # module expects methods named as "match_within_[DEPT]_[CLOTHING_TYPE[:group]]
  # * match_within_womens_top
  # * match_within_womens_accessories
  def add_mapper(mapper)
    m = Mapper.new
    if mapper.is_a?(Hash)
      m.mapper = mapper
      m.extend(SizeMapperHashMethods)
    else
      klass_name = mapper.to_s.classify
      begin
        klass_name.constantize
      rescue
        begin
          require "size_mappers/#{mapper}"
        rescue MissingSourceFile
          name = File.split(@fetcher_class.path).last.match(/^([^.]+).rb$/)[1]
          require File.dirname(__FILE__) + "/../../fetchers/#{name}/#{mapper}"
        end
      end
      klass = klass_name.constantize
      klass.instance_methods.reject{|m| m =~ /^default_/}.each do |method_name|
        klass.send(:alias_method, "default_#{method_name}", method_name)
      end
      m.extend(klass)
    end
    self.mappers << m
    self
  end

  # ==Generate the match method name from an item
  # match_within_[DEPT]_[CLOTHING_TYPE[:GROUP]]
  def method_name_from_item(item)
    "match_within_#{item.dept.to_s}_#{item.clothing_type[:group].to_s}"
  end

  # ==Override some methods from the last mapper added
  # When we mix in modules we alias the original methods to default_[ORIGINAL_METHOD_NAME]
  # ===ex:
  #   size_mapper = SizeMapper.new
  #   size_mapper.add_mapper(:test_size_mapper)
  #   size_mapper.override_last do
  #     def match_within_womens_top(value, item)
  #       if value.downcase.gsub(/\s/, '') == 'one'
  #         %w(XS)
  #       else
  #         default_match_within_womens_top(value, item)
  #       end
  #     end
  #   end
  def override_last(&block)
    @mappers.last.instance_eval(&block)
  end
  
end

# == Module to create all match and default_match methods when a hash is passed in as a global mapper
module SizeMapperHashMethods
  Department.all.each do |dept|
    ClothingType.all.collect{|c| ClothingType[c, dept][:group]}.uniq.each do |group|
      next if group.nil?
      define_method "match_within_#{dept.to_s}_#{group.to_s}" do |value, item|
        @mapper[value]
      end
      define_method "default_match_within_#{dept.to_s}_#{group.to_s}" do |value, item|
        @mapper[value]
      end
    end
  end
end