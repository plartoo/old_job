
$:.unshift File.join(File.dirname(__FILE__), 'data')

require 'parse_agent'
require 'item_image'
require 'clothing_type_matcher'

class ItemParseAgent < ParseAgent # :nodoc:
  attr_accessor :page
  attr_writer :structure
  attr_reader :category

  NUM_OF_RETRIES = 3

  def each(conditions, category = nil, &block)
    @category = category
    if conditions["custom_item_list"]
      each_with_custom_item_list(conditions,&block)
    else
      each_without_custom_item_list(conditions,&block)
    end
  end
  
  def base_nodes
    return nil unless @structure
    if @page.respond_to? :parser
      @base_nodes = @structure.get_nodes(@page.parser)
    elsif @agent.use_nokogiri
      @base_nodes = @structure.get_nodes(@page)
    else
      @base_nodes = @structure.get_nodes(Nokogiri::XML.parse(@page.content))
    end
  end

  def each_without_custom_item_list(conditions)
    base_nodes.each do |el|
      item = Item.new
      index_conditions = conditions.reject {|n, c| c.from_detail_page}
      detail_conditions = extract_detail_conditions(conditions)
      index_conditions.each do |part_name, part|
        value = process_part(el, part_name, part)
        item.send("#{part_name}=".to_sym, value)
      end

      next unless item.product_url

      if detail_conditions.size > 0
        next unless @detail_link
        retry_count = 0
        begin
          click! @detail_link
          process_detail_conditions_for_item(item, detail_conditions)
          back!
        rescue Timeout::Error
          if retry_count < NUM_OF_RETRIES
            retry_count += 1
            @fetcher_class.log.warn "\n\nitem_parse_agent.rb: Rescued execution timeout in each_without_custom_item_list\n\n"
            retry
          end
          @fetcher_class.log.warn "\n\nitem_parse_agent.rb:: ERROR: Execution timeout in each_without_custom_item_list\n\n"
          next
        end
      end
    
      yield item
    end
  end
  
  def extract_detail_conditions(conditions)
    conditions.reject {|n, c| !c.from_detail_page}
  end
  
  def process_detail_conditions_for_item(item, detail_conditions)
    detail_conditions.each do |part_name, part|
      value = process_part(@page.parser, part_name, part)
      item.send("#{part_name}=".to_sym, value)
    end
  end
  
  def each_with_custom_item_list(conditions)
    conditions["custom_item_list"].produce_list(@page, self)
    conditions["custom_item_list"].each do |item_data|
      item = Item.new
      conditions["custom_item_list"].set_item_data(item, item_data, self)
      unless item.valid_attributes?
         @fetcher_class.log.warn "Item created by define_custom_item_list_iterator is not valid\n#{item.to_yaml}"
         next
      end
      detail_conditions = extract_detail_conditions(conditions)
      if detail_conditions.size > 0
        go_to(item.product_url)
        process_detail_conditions_for_item(item, detail_conditions)
      end
      yield item
    end
  end

  private
  def process_part(element, part_name, part)
    if part.is_a?(CustomConditionSet) && part.direct_value
      value = part.get_value(element)
    else
      node = part.get_node(element)
      return if node.nil?

      value = nil
      value = self.send("parse_#{part_name}".to_sym, node, part)

      if part_name == 'product_url'
        @detail_link = get_mechanize_links_from_nodes([node]).first
      end
    end

    value
  end

  def parse_description(node, part)
    get_embedded_text(node).strip
  end

  def parse_price(node, part)
    get_embedded_text(node)
  end

  alias_method :parse_original_price, :parse_price
  alias_method :parse_sale_price, :parse_price

  def parse_product_url(node, part)
    node[:href]
  end
  
  def parse_product_image(node, part)
    part.get_image(node)
  end

  def parse_brand(node, part)
    get_embedded_text(node).strip
  end

  def parse_notice(node, part)
    get_embedded_text(node).strip
  end

end 
