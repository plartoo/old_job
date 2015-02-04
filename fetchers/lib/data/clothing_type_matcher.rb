require 'base'
require 'clothing_type'

class ClothingTypeMatcher < Base # :nodoc:

  @@i18n_version = nil
  @@fetcher_class = nil

  def self.patterns
    @@patterns ||= self.load_patterns
  end

  def self.load_fetcher_specific_clothing_type_patterns
    fetcher_name = @@fetcher_class.fetcher_name

    fetcher_dir = File.join(Configuration.fetchers_dir,fetcher_name)
    fetcher_pattern_file = File.join(fetcher_dir, "#{fetcher_name}_#{@@i18n_version}_patterns.yml")

    if File.exist?(fetcher_pattern_file)
      YAML.load_file(fetcher_pattern_file)
    end
  end

  def self.load_patterns
    @@patterns = self.load_fetcher_specific_clothing_type_patterns if @@fetcher_class
    @@patterns ||= {}

    pattern_module = "clothing_type_patterns_#{@@i18n_version}"
    require "clothing_type_patterns/clothing_type_patterns_#{@@i18n_version}"
    %w(Mens Womens Boys Girls).each do |d|
      @@patterns[d.downcase] ||= []
      @@patterns[d.downcase] += pattern_module.camelize.constantize.const_get("#{d}Patterns")
      @@patterns[d.downcase] += pattern_module.camelize.constantize::CommonPatterns
    end

    @@patterns
  end

  def self.determine_clothing_type(fetcher_class,item)
    self.fetcher_class = fetcher_class

    type_sym = determine_clothing_type_sym(item.description, item.dept)

    if type_sym

      return ClothingType[type_sym, item.dept]
    end
    img_url = item.product_image.url rescue nil
    fetcher_class.log.info "Failed to determine clothing type for #{item.description}"
    fetcher_class.log.info "clothing_type_match_failed for: #{item.dept} ==> #{item.product_url} ==> #{img_url}"
    nil
  end

  def self.determine_clothing_type_sym(text,department)
    self.patterns[department.to_s.downcase].each do |pattern, type_sym|
      if text =~ pattern
        return type_sym
      end
    end
    nil
  end

  def self.i18n_version=(i18n_version)
    @@i18n_version = i18n_version
  end

  def self.fetcher_class=(fetcher_class)
    @@fetcher_class = fetcher_class
  end

  def self.fetcher_class
    @@fetcher_class
  end
end
