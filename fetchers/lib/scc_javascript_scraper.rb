require 'scc_scraper'
require 'scc_parse_agent'

class SCCFromJavaScriptScraper < SCCScraper

  def scrape_internal(options) # :nodoc:
    script = ConditionSet.new nil do
      is "script"
    end

    @agent.each(script) do |script|
      lines = script.text.split("\n")
      lines.select{|x| @pattern.match(x)}.each do |line|
        match_data = @pattern.match(line)
        
        size = match_data[@mappings[:size]].rstrip
        color = match_data[@mappings[:color]].rstrip

        process_scc(size, color)
      end
    end
  end

  def pattern(pattern)
    @pattern = pattern
  end

  def mappings(h)
    unless h[:size] and h[:color]
      raise "insufficient data"
    end
    @mappings = h
  end

end
