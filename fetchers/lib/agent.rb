require File.dirname(__FILE__) + "/dependencies"

class Agent 
  
  attr_reader :request_count, :request_time, :escape_uri
  attr_accessor :use_nokogiri

  @@data_sender = nil
  
  def initialize(fetcher_class)
    @mechanize_agent = Mechanize.new
    @mechanize_agent.max_history = 1
    @request_count = 0
    @request_time = 0
    @use_nokogiri = false
    @fetcher_class = fetcher_class
  end


  def self.time_execution_of
    start = Time.now.to_f
    result = yield
    # want timings in Milliseconds
    time_spent = ((Time.now.to_f - start) * 1000).to_i
    
    if @@data_sender
      @@data_sender.send("request_time",time_spent)
      @@data_sender.send("num_requests",1)
    end
    
    [result,time_spent]
  end
  
  def get(*args)
    result,time_spent = Agent.time_execution_of do
      @mechanize_agent.get(*args)
    end

    if $output_mechanize_resp_size_to
      `echo #{@fetcher_class.fetcher_name}\t#{result.content.size}\t#{$key} >> #{$output_mechanize_resp_size_to}`
    end

    @request_time += time_spent
    @request_count += 1
    result
  end

  def always_escape_uri!
    @escape_uri = true
  end
  
  def should_escape_uri?
    !@escape_uri.nil?
  end

  def post(*args)
    result,time_spent = Agent.time_execution_of do
      @mechanize_agent.post(*args)
    end
    @request_time += time_spent
    @request_count += 1
    result
  end
  
  def method_missing(m,*args)
    if args.length > 0
      @mechanize_agent.send(m.to_sym,*args)
    else
      @mechanize_agent.send(m.to_sym)
    end
  end

  def self.data_sender
    @@data_sender
  end

  def self.data_sender=(data)
    @@data_sender = data
  end
  
end