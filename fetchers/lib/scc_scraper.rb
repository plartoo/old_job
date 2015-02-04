$:.unshift File.join(File.dirname(__FILE__), 'data')

require 'size_color_configuration'
require 'size'
require 'size_matcher'

class SCCScraper
  attr_accessor :agent, :extended_description_definition, :additional_images_definition, :related_vendor_keys_definition
  attr_reader :item, :fetcher_class
  attr_accessor :previous_page

  @@grab_extended_description = true
  @@grab_additional_images = true
  @@grab_related_vendor_keys = false
  @@grab_scc_label_value_pairings = false
  
  def self.initialize_scraper(fetcher_class, type, options = {}, &definition) # :nodoc:
    type.new(fetcher_class, options, &definition)
  end

  def initialize(fetcher_class,options = {}, &definition) # :nodoc:
    @fetcher_class = fetcher_class
    @definition = definition
    @ignored_sizes=[]
    @configuration = options
    @previous_page = nil
  end

  def extended_description_data(&definition)
    return unless @@grab_extended_description

    @extended_description_definition = definition
  end

  def additional_images(&definition)
    return unless @@grab_additional_images
    
    @additional_images_definition = definition
  end

  def related_vendor_keys(&definition)
    return unless @@grab_related_vendor_keys

    @related_vendor_keys_definition = definition
  end

  def scc_label_value_pairings(&definition)
    return unless @@grab_scc_label_value_pairings

    @scc_label_value_pairings_definition = definition
  end

  def scrape(options) # :nodoc:
    item = options[:item]
    setup!(item)
    url = item.product_url
    
    unless @agent.go_to(url)
      raise "could not follow url: #{url}"
    end

    begin
      scrape_internal(options)
    rescue Exception => e
      @fetcher_class.log.error("Exception encountered with item:")
      @fetcher_class.log.error(@item.product_url)
      @fetcher_class.log.error(e.to_s)
      @fetcher_class.log.error(e.backtrace.join("\n"))
      if options[:debug]
        @fetcher_class.log.debug "Exception encountered with item:"
        @fetcher_class.log.debug @item.product_url
        @fetcher_class.log.debug e.to_s
        @fetcher_class.log.debug e.backtrace.join("\n")
      end
    end
    
    
    handle_extended_description!(item)
    handle_additional_images!(item)
    handle_related_vendor_keys!(item)
    
    @previous_page = @agent.page

    @sccs
  end

  def handle_extended_description!(item)
    if @extended_description_definition
      item.extended_description = @extended_description_definition.call(@agent.page)
      raise "Invalid extended description" unless item.extended_description.is_a?(Hash)
    end
  end

  def handle_additional_images!(item)
    if @additional_images_definition
      item.additional_images = @additional_images_definition.call(@agent.page)
      raise "Invalid additional images" unless item.additional_images.is_a?(Hash)
    end
  end

  def handle_related_vendor_keys!(item)
    if @related_vendor_keys_definition
      temp_data = @related_vendor_keys_definition.call(@agent.page)
      raise "Invalid related items" unless temp_data.is_a?(Array)
      item.related_vendor_keys = temp_data.flatten.compact.uniq
    end
  end

  def handle_scc_label_value_pairings!(item)
    if @scc_label_value_pairings_definition
      item.scc_label_value_pairings = @scc_label_value_pairings_definition.call(@previous_page)
    end
  end

  def ignored_sizes(*sizes)
    @ignored_sizes = sizes
  end

  def extractors(*extractors)
    @extractors = extractors
  end
  
  def testing
    @testing = true
  end

  def matchers(mappers = {})
    @matchers = mappers.is_a?(SizeMapper) ? SizeMatcher.new(mappers) : SizeMatcher.new(SizeMapper.new(@fetcher_class).add_mapper(mappers))
  end

  def self.grab_extended_description=(flag)
    @@grab_extended_description = flag
  end

  def self.grab_additional_images=(flag)
    @@grab_additional_images = flag
  end

  def self.grab_related_vendor_keys=(flag)
    @@grab_related_vendor_keys = flag
  end

  def self.grab_scc_label_value_pairings=(flag)
    @@grab_scc_label_value_pairings = flag
  end

private
  def scrape_internal(options)
    raise "internal scrape not implemented"
  end

  def setup!(item)
    @item = item
    @sccs = []
    return if @agent
    @agent = SCCParseAgent.new(@fetcher_class)
    self.instance_eval(&@definition)
    @matchers ||= self.matchers
  end

  def process_scc(size, color)
    @fetcher_class.log.debug "\nProcess SCC for #{@item.description}\n"
    if @testing
      sizes = [size]
    else
      sizes = map_size(size, @item)
    end

    sizes.each do |size_hash|
      if @testing
        @sccs << {:size => size, :color => color}
      else
        scc = SizeColorConfiguration.new(size_hash, color)
        @sccs << scc.to_h if scc.valid? && !@sccs.include?(scc.to_h)
      end 
    end
  end

  def map_size(size_str, item)
    (@extractors || []).each do |pattern|
      if pattern =~ size_str
        size_str = pattern.match(size_str)[1]
      end
    end

    @matchers.match(size_str, item).map do |size|
      begin
        Size.get_size(@fetcher_class,size, item)
      rescue Size::SizeException
        @fetcher_class.log.info "Size::SizeException => #{item.inspect}"
        nil
      end
    end.flatten.compact
  end

end
