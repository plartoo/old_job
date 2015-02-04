require 'parse_agent'

class CategoryParseAgent < ParseAgent
  
  def get_attr_from_link(link, attr)    
    if attr.is_a?(ConditionSet)
      link = attr.get_node(link.node)
    elsif attr && link.node[attr]
      return link.node[attr]
    end

    return Utils.replace_non_ascii_with(get_embedded_text(link))
  end

end
