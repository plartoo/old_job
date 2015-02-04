require 'parse_agent'

class SCCParseAgent < ParseAgent # :nodoc:
  attr_accessor :page

  def each(condition_set)
    nodes = condition_set.get_nodes(@page).clone
    nodes = nodes[1..-1] if condition_set.options[:skip_first]
    nodes.each do |node|
      yield node
    end
  end

  def each_value(condition_set)
    each(condition_set) do |node|
      yield get_embedded_text(node)
    end
  end

end
