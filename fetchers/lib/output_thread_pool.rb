require 'fetcher_thread_pool'
require 'thread_safe_counter'

class OutputThreadPool < FetcherThreadPool

  attr_accessor :output_stream, :output_queue, :output_counter
  attr_accessor :duplicate_output_counter

  def initialize(configuration)
    super(configuration)
    @input_queue = configuration[:output_queue]
    @output_counter = ThreadSafeCounter.new
    @duplicate_output_counter = ThreadSafeCounter.new
  end

  def join
    @input_queue << TERMINATE_WORK
    @threads.each{|thr| thr.join}
  end

  def spawn_and_return_thread(output_test_stream = nil)
    Thread.new(output_test_stream) do |output_test_stream|

      @output_stream = create_output_stream output_test_stream

      @output_stream << "--- \n"
      loop do
        break unless do_iteration

        break unless fetcher_has_time_left?
        Thread.pass
      end
      @output_stream.close if @output_stream.is_a?(File)
    end
  end

  def do_iteration
    unless @input_queue.size > 0
      return true
    end

    data_to_write,should_continue = grab_num_from_queue(@input_queue,@input_queue.size)
    write_data data_to_write

    should_continue
  end

  def create_output_stream(output_test_stream=nil)
    output_stream = nil
    if output_test_stream
      output_stream = output_test_stream
    else
      dir = File.join(@configuration[:feed_path],@fetcher_class.fetcher_name)
      FileUtils.mkdir_p dir
      output_stream = File.open(File.join(dir,"#{@configuration[:date]}.yml"), "w")
    end
    output_stream
  end

  def write_data(data)
    data.each{|item|
      @output_counter.increment
      line = item.to_yaml.gsub("--- \n","- ").gsub("\n","\n  ").gsub(/\n  $/,"\n")
      @output_stream << line
    }
  end

  def grab_num_from_queue(queue,num)
    data = []
    item = nil
    num.times do
      item = queue.pop
      if item.eql?(TERMINATE_WORK)
        break
      elsif item == POLL_AGAIN
        next
      end

      data << item
    end
    [data, item != TERMINATE_WORK]
  end
  
end