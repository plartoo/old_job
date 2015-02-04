require 'scc_scraper'
require 'scc_parse_agent'

class SCCFromHTMLScraper < SCCScraper

  def scrape_internal(options) # :nodoc:
    if @size_def.is_a?(ConditionSet)
      if @color_def.is_a?(Proc)
        color = @color_def.call(@item)
      else
        color = @color_def
      end
      @agent.each_value(@size_def) do |size|
        process_scc(size, color)
      end

      if @sccs.size == 0 && @empty_means_all
        process_scc("no size", color)
      end
    else
      @agent.each_value(@color_def) do |color|
        process_scc(@size_def, color)
      end

      if @sccs.size == 0 && @empty_means_all
        process_scc(@size_def, "")
      end
    end    
  end

  def size(options=nil, &block)
    if options && options[:no_size]
      @size_def = "no size"
    elsif options && options[:from_item] && block_given?
      @size_def = block.call(@item)
    else
      @empty_means_all = options && options[:empty_means_all]
      @size_def = ConditionSet.new options, &block
    end
  end

  def color(options=nil, &block)
    if options && options[:no_color]
      @color_def = ""
    elsif options && options[:from_item] && block_given?
      @color_def = block
    else
      @color_def = ConditionSet.new &block
    end
  end

end
