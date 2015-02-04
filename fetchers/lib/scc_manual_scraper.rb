require 'scc_scraper'
require 'scc_parse_agent'

class SCCManualScraper < SCCScraper

  def scrape_internal(options) # :nodoc:
    result = @block.call(@item, @agent)
    result.each do |sc|
      process_scc(*sc)
    end
  end

  def process(&definition)
    @block = definition
  end

end
