require 'scc_scraper'
require 'scc_parse_agent'
require 'json'

class SCCFromHashedJSONScraper < SCCScraper

  def scrape_internal(options) # :nodoc:
    script = ConditionSet.new nil do
      is "script"
    end

    @agent.each(script) do |script|
      if script.to_s.index(@json_variable)
        json = script.child.to_s.delete("\n\t\r").gsub(/\s+/, '')
        json = json.slice(json.index('=')+1, json.size)
        json = JSON.parse(json) rescue next
        
        color_hash = {}
        return unless json[@color_hash_name]
        json[@color_hash_name].each do |color, color_info|
          color_hash[color] = color_info[@color_name_in]
        end
        
        return unless json[@size_hash_name]
        json[@size_hash_name].each do |size, size_info|
          if size == 'P'
            size = 'PETITE'
          end
          size_info[@colors_in_size_name].each do |c|
            color = color_hash[c]
            process_scc(size, color)
          end
        end
      end
    end
  end

  def json_variable(var_name)
    @json_variable = var_name
  end

  def size_hash_name(name)
    @size_hash_name = name
  end

  def colors_in_size_name(name)
    @colors_in_size_name = name
  end

  def color_hash_name(name)
    @color_hash_name = name
  end

  def color_name_in(name)
    @color_name_in = name
  end

end
