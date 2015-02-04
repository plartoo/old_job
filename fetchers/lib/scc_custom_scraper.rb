require 'scc_scraper'
require 'scc_parse_agent'

class SCCCustomScraper < SCCScraper

  attr_accessor :sccs, :agent

  def scrape_internal(options) # :nodoc:
    @agent.each(@give_me) do |part|
      result = @block.call(part)
      next unless result

      if result.is_a?(Hash)
        result[:all_items].map! do |item|
          item.scc = process_spawned_case_scc(item)
          item
        end
        @sccs = result
        return
      end

      if @all_at_once
        result.each do |sc|
          process_scc(*sc)
        end
      else
        process_scc(*result)
      end
    end
  end

  def give_me(&definition)
    @give_me = ConditionSet.new(&definition)
  end

  def all_at_once
    @all_at_once = true
  end

  def process(&definition)
    @block = definition
  end

  private

  # e.g., item.scc --> {:color=>"BLACK", :size=>"0P/4P"}
  def process_spawned_case_scc(item)
    spawn_sccs = []
    item.scc.each do |size_color|

      mapped_sizes = map_size(size_color[:size], item) rescue [] # will return something like this: [{:type_bm=>0, :bm=>19}, {:type_bm=>0, :bm=>21}]

      mapped_sizes.each do |size_type_info|
        temp_scc = size_color.merge(size_type_info)
        scc = SizeColorConfiguration.new(temp_scc, temp_scc[:color])
        if scc.valid?
          spawn_sccs.push scc.to_h
        end
      end
    end
    spawn_sccs.uniq
  end

end
