require File.dirname(__FILE__) + "/dependencies"

class ParseAgent # :nodoc:
  attr_accessor :agent
  attr_writer :navigation_override
  
  TRY_LIMIT = 3

  def initialize(fetcher_class)
    @agent = FetcherHelperMethods.agent(fetcher_class)
    @fetcher_class = fetcher_class
    fetcher_class.setup_block.call(@agent) if fetcher_class.setup_block
  end

  def auth(user, passwd)
    @agent.auth(user, passwd)
  end

  def go_to(url)
    tries = 0
    begin
      tries += 1
      if @agent.should_escape_uri?
        require 'uri'
        url = URI.escape(url)
      end
      @page = @agent.get(url)
      if @agent.use_nokogiri
        @page = Nokogiri.parse(@page.content)
      end
      @agent.history.clear
      return true
    rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, Timeout::Error, Net::HTTPBadResponse => e
      @fetcher_class.log.error("Exception in go_to for url \n#{url}\n#{e.message}\n#{e.backtrace.join("\n")}")
      retry if tries < TRY_LIMIT
    rescue Exception => e
      @fetcher_class.log.error("Exception in go_to for url \n#{url}\n#{e.message}\n#{e.backtrace.join("\n")}")
    end
    false
  end
  
  def post(url, options)
    result = @agent.post(url, options)
    back!
    result
  end

  def click!(link)
    @last_page = @page
    @page = @agent.click link
  end

  def back!
    @agent.back
    @page = @last_page || @agent.current_page
  end

  def visited?(url)
    @agent.visited?(url)
  end
  
  def links(conditions)
    get_mechanize_links_from_nodes(get_link_nodes(conditions))
  end

  def urls(conditions)
    get_link_nodes(conditions).map do |node|
      node[:href]
    end
  end

private
  def get_embedded_text(link)
    if link.is_a? Mechanize::Page::Link
      node = link.node
      return get_embedded_text_from_node(node)
    elsif link.is_a? String
      return Utils.cleanup(link)
    else
      return get_embedded_text_from_node(link)
    end
  end
  
  def get_embedded_text_from_node(node)
    next_node = non_whitespace_child(node)
    while !next_node.nil?
      node = next_node
      next_node = non_whitespace_child(node)
    end
    Utils.cleanup(node.to_s)
  end
  
  def non_whitespace_child(node)
    node.children.select{|x| x.to_s.match(/\S/m)}.first
  end

  def get_link_nodes(conditions)
    conditions.get_nodes(@page)
  end

  def get_mechanize_links_from_nodes(nodes)
     if !@page.respond_to? :links
       return []
     end
    @page.links.reject do |link|
      !nodes.include?(link.node)
    end
  end

  def link_css_selector_from_conditions(conditions)
    conditions.inject("a") do |selector, c| 
      selector += c.get_css_selector
    end
  end

end
