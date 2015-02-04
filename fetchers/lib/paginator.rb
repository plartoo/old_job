require 'condition_set'

class Paginator # :nodoc:
  attr_accessor :conditions, :view_all
  attr_accessor :logger, :stop

  def initialize(logger=nil, &definition)
    self.logger = logger || fatal_logger
    if block_given?
      self.instance_eval(&definition)
    end
  end

  def view_all_append(string)
    @view_all = string
  end

  def preprocess(&block)
    @preprocess = block
  end

  def url_pattern(pattern)
    @url_pattern = pattern
  end

  def increment_start(start)
    @start = start
  end

  def max_page_limit(stop)
    @stop = stop
  end
  
  def increment_step(step)
    @step = step
  end

  def transformer(&block)
    @url_transformer = block
  end
  
  def select(&definition)
    @conditions = ConditionSet.new nil, &definition
  end

  def each(agent, scraper, start_url)
    if @preprocess
      start_url = @preprocess.call(start_url)
    end

    if @view_all
      urls = [start_url + @view_all]
    elsif @conditions

      unless agent.go_to(start_url)
        raise "could not follow url: " + start_url.to_s
      end
      
      urls = agent.urls(@conditions).map do |url|
        scraper.complete_href(url)
      end

      urls.uniq!

      unless urls.include?(start_url)
        # we need to use 'unshift' because it's the safetest to start pagination
        # from the original/start_url
        urls.unshift start_url
      end

    elsif @url_pattern

      @loop_count = 0
      @stop ||= 0
      @position = @start || 0
      @step ||= 1
      while true
        break if ((@stop!=0)&&(@loop_count > @stop))
        url = start_url.sub(@url_pattern, '\1' + @position.to_s + '\2')
        if @url_transformer
          url = @url_transformer.call(url)
        end
        yield url
        @loop_count += 1
        @position += @step
      end
      return

    else
      urls = start_url.is_a?(Array) ? start_url : [start_url]
    end

    urls.each do |url|
      if @url_transformer
        yield @url_transformer.call(url)
      else
        yield url
      end
    end
  end

  def fatal_logger
    log = Logger.new(STDOUT)
    log.level = Logger::FATAL
    log
  end
end
