require 'condition'

class CustomConditionSet
  attr_accessor :from_detail_page, :direct_value
  
  def initialize(options, &definition)
    @from_detail_page = options ? options[:from_detail_page] : nil
    @direct_value = options ? options[:direct_value] : nil
    @process = definition
  end

  def get_node(element)
    @process.call(element)
  end

  alias_method :get_value, :get_node

  def processor(&block)
    @process = block
  end

end
