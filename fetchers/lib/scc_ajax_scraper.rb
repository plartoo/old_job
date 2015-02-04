require 'scc_scraper'
require 'scc_parse_agent'

class SCCFromAjaxScraper < SCCScraper

  def parameters(options=nil, &block)
    @parameters = ParameterSet.new(options, &block)
  end

  def url(url)
    @url = url
  end

  def process(&block)
    @process = block
  end

private
  def scrape_internal(options) # :nodoc:
    @parameters.each(@item, @agent.page) do |options|
      result = @agent.post(@url, options)
      next unless result
      result = @process.call(result)
      result.each do |scc|
        process_scc(*scc)
      end
    end
  end

  class ParameterSet # :nodoc:
    def initialize(options=nil, &block)
      @params = options || {}
      @varied_params = {}
      if block_given?
        self.instance_eval(&block)
      end
    end

    def each(item, page)
      param_lists = get_param_lists(item, page)
      param_order, param_combinations = get_param_combinations(param_lists)

      param_combinations.each do |combo|
        options = {}
        combo.each_with_index do |c, i|
          options[param_order[i]] = c
        end
        yield options.merge(@params)
      end
    end

    private
    def get_param_lists(item, page)
      list = []
      @varied_params.each do |param_name, param|
        params = param[:processor].call(param[:from_where] == :from_item ? item : page)
        params = [params] unless params.is_a?(Array)
        params.unshift(param_name)
        list << params
      end

      list
    end

    def get_param_combinations(list)
      stack = []
      param_order = []
      list.each do |p|
        stack.push p[1, p.size]
        param_order.unshift p[0]
      end
      
      while stack.size > 0
        top = stack.pop
        if stack.size == 0
          return param_order, top
        end

        bottom = stack.pop
        splice = []
        top.each do |t|
          unless t.is_a?(Array)
            t = [t]
          end

          bottom.each do |b|
            t.push b
            splice.push t
          end
        end
        
        stack.push splice
      end
    end

    def param(param_name, from_where, &block)
      @varied_params[param_name] = {:from_where => from_where, :processor => block}
    end

    def method_missing(method_name, *args, &block)
      @varied_params[method_name] = {:from_where => args[0], :processor => block}
    end
  end

end
 
