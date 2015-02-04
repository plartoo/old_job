require 'yaml'
require File.dirname(__FILE__) + "/../configuration"

module ClothingType # :nodoc:

  class ClothingTypeException < StandardError; end;
  class ClothingTypeNotFound < ClothingTypeException; end;

  @@common_clothing_types = nil
  @@department_clothing_types = {}

  def self.[](type_sym, department)
    clothing_type = self.common_clothing_types.merge(self.department_clothing_types(department))[type_sym]
    raise ClothingTypeNotFound if clothing_type.nil?
    clothing_type
  end

  def self.common_clothing_types
    @@common_clothing_types ||= YAML.load_file(File.join(Configuration.config_dir, "..", "common", "common_clothing_types.yml"))
  end
  
  def self.department_clothing_types(department)
    @@department_clothing_types[department.to_sym] ||= 
      YAML.load_file(File.join(Configuration.config_dir, "..", "common", "#{department}_clothing_types.yml"))
  rescue Errno::ENOENT
    @@department_clothing_types[department.to_sym] = {}
  end
    
  def self.all
    self.common_clothing_types.keys
  end

end
