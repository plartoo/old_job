require 'condition'

class ConditionSet
  attr_accessor :from_detail_page, :options

  def initialize(options=nil, &definition)
    @conditions = []
    @options = options || {}
    @element = options ? options[:element] : nil
    @from_detail_page = options ? options[:from_detail_page] : nil
    self.instance_eval(&definition)
    raise "no element type specified" if @element.nil?
  end

  def get_node(element)
    ancestor_nodes = get_nodes_from_ancestor(element)
    ancestor_nodes.each do |node|
      nodes = node.search(get_selector)
      next if nodes.nil? || nodes.size == 0
      return nodes.find{|node| matches?(node)}
    end
    nil
  end

  def get_nodes(element)
    if element.is_a? Mechanize::Page
      element = element.parser
    end
    ancestor_nodes = get_nodes_from_ancestor(element)
    nodes = []
    ancestor_nodes.each do |ancestor_node|
      ancestor_node.search(get_css_selector).each do |node|
        append = true
        @conditions.each do |c|
          append = c.matches?(node)
        end
        nodes << node if append
      end
    end
    nodes
  end
  
  def with(hash)
    hash.each do |attr, value|
      add_condition(attr.to_s, value)
    end
  end

  def add_condition(attr, value)
    @conditions << Condition.new(attr, value)
  end

  def is(tag)
    @element ||= tag
  end

  def ancestor(options={}, &block)
    if options && options[:selector]
      @ancestor = SimpleConditionSet.new(options)
    else
      @ancestor = ConditionSet.new(&block)
    end
  end

  def get_selector
    base = './/' + @element
    @conditions.inject(base) do |selector, c|
      selector += c.get_xpath_selector
    end
  end

  def get_css_selector
    base = @element
    @conditions.inject(base) do |selector, c|
      selector += c.get_css_selector
    end
  end

private
  def get_nodes_from_ancestor(element)
    if @ancestor
      return @ancestor.get_nodes(element)
    else
      return [element]
    end
  end

  def matches?(node)
    @conditions.all? do |c|
      c.matches?(node)
    end
  end

  def method_missing(method_name, *args)
    pieces = method_name.to_s.split("_")
    unless pieces.size > 1 && pieces[0] == "with"
      return super.method_missing(method_name, *args)
    end

    add_condition(pieces[1], args[0])
  end

end
