
class SimpleConditionSet # :nodoc:
  attr_accessor :from_detail_page, :direct_value

  def initialize(options = {})
    @from_detail_page = options[:from_detail_page]
    @direct_value = options[:direct_value]
    @selector = options[:selector]
  end
  
  def get_node(element)
    nodes = element.search(@selector)
    (nodes || []).first
  end

  def get_nodes(element)
    if element.is_a? Mechanize::Page
      element = element.parser
    elsif element.is_a? Mechanize::File
      return []
    end
    element.search(@selector)
  end
end
