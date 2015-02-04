require 'base'

class Scraper # :nodoc:

  def main_url(url, force=false)
    if force
      @main_url = url
    else
      @main_url ||= url
    end
  end

  def complete_href(href)
    unless href =~ /^(http|file).*/
      href = '/' + href unless href[0...1] == '/'
      href = @main_url + href
    end
    href
  end

  def testing
    @testing = true
    main_url("file://" + File.expand_path(File.join(File.dirname(__FILE__), '..', 'test', 'html')), true)
  end

end
