require File.dirname(__FILE__) + '/test_helper'

class ItemParseAgentTest < Test::Unit::TestCase

  def setup
    @agent = ItemParseAgent.new(Victoriassecret)
  end
  
  def test_base_nodes_returns_nil_when_structure_is_nil
    @agent.instance_variable_set("@structure",nil)
    assert_nil @agent.base_nodes
  end
    
end
