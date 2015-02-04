require File.dirname(__FILE__) + '/test_helper'

class ParseAgentTest < Test::Unit::TestCase

  def setup
    @agent = ParseAgent.new(Victoriassecret)
  end

  def test_get_embedded_text_extracts_links_with_whitespace
    str =<<-EOF
    <a>
      <span>Womens</span>
    </a>
    EOF
    doc = Nokogiri::XML::parse(str)
    node = doc.search("a").first
    assert_equal "Womens", @agent.send(:get_embedded_text_from_node,node)
  end

  def test_get_embedded_text_extracts_links_with_no_children
    str =<<-EOF
    <a href="/b/321181031?ie=UTF8&amp;descripttion=As-Seen-on-TV-Womens" title="As Seen on TV">
                     As Seen on TV
                   </a>
    EOF
    doc = Nokogiri::XML::parse(str)
    node = doc.search("a").first
    assert_equal "As Seen on TV", @agent.send(:get_embedded_text_from_node,node)
  end

  # Obtained Exception names of NETHTTP from
  #<http://tammersaleh.com/posts/rescuing-net-http-exceptions>
  #begin
  #  response = Net::HTTP.post_form(...) # or any Net::HTTP call
  #rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
  #       Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
  #  ...
  #end

  def test_go_to_returns_false_when_get_raises_timeout_error
   @agent.agent.expects(:get).raises(Timeout::Error)
   assert_equal false, @agent.go_to("http://no-where.com")
 end

  def test_go_to_returns_false_when_get_raises_invalid_argument_error
   @agent.agent.expects(:get).raises(Errno::EINVAL)
   assert_equal false, @agent.go_to("http://no-where.com")
  end

  def test_go_to_returns_false_when_get_raises_connection_forcibly_closed_error
   @agent.agent.expects(:get).raises(Errno::ECONNRESET)
   assert_equal false, @agent.go_to("http://no-where.com")
  end

  def test_go_to_returns_false_when_get_raises_http_bad_response_error
   @agent.agent.expects(:get).raises(Net::HTTPBadResponse)
   assert_equal false, @agent.go_to("http://no-where.com")
  end

  def test_go_to_returns_false_when_get_raises_http_bad_response_error
   @agent.agent.expects(:get).raises(Net::HTTPBadResponse)
   assert_equal false, @agent.go_to("http://no-where.com")
  end

  def test_go_to_returns_false_when_get_raises_http_header_syntax_error
   @agent.agent.expects(:get).raises(Net::HTTPHeaderSyntaxError)
   assert_equal false, @agent.go_to("http://no-where.com")
  end

  def test_go_to_returns_false_when_get_raises_net_protocol_error
   @agent.agent.expects(:get).raises(Net::ProtocolError)
   assert_equal false, @agent.go_to("http://no-where.com")
  end

 def test_go_to_returns_true_when_no_exception_occurs
   @agent.agent.expects(:get).returns("<html>")
   assert_equal true, @agent.go_to("http://no-where.com")
 end

 def test_should_retry_when_a_timeout_error_occurs
   @agent.agent.stubs(:get).raises(Timeout::Error).returns("<html>")
   assert_equal true, @agent.go_to("http://no-where.com")
 end

  def test_should_return_false_after_too_many_retries_when_a_timeout_error_occurs
   @agent.agent.expects(:get).raises(Timeout::Error).raises(Timeout::Error).raises(Timeout::Error).raises(Timeout::Error).returns("<html>")
   assert_equal false, @agent.go_to("http://no-where.com")
 end

  def test_page_variable_is_assigned_to_whatever_go_to_returns
    @agent.agent.expects(:get).returns("<html>")
    @agent.go_to("http://no-where.com")
    assert_equal "<html>", @agent.instance_variable_get("@page")
  end

end
