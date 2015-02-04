require File.dirname(__FILE__) + '/test_helper'

class AgentTest < Test::Unit::TestCase

  def setup
    @agent = Agent.new(Victoriassecret)
  end

  def test_escape_uri_call_sets_appropriate_boolean_value_to_escape_uri_variable
    @agent.expects(:always_escape_uri!).returns(true)
    assert_equal true, @agent.always_escape_uri!
  end

  def test_escape_uri_check_returns_appropriate_boolean_value
    assert_equal false, @agent.should_escape_uri?
    @agent.always_escape_uri!
    assert_equal true, @agent.instance_variable_get("@escape_uri")
  end

end
