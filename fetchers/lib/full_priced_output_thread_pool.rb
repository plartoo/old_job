require 'output_thread_pool'
require 'thread_safe_counter'

class FullPricedOutputThreadPool < OutputThreadPool

  def initialize(configuration)
    super(configuration)
    @seen_unique_ids = ThreadSafeHash.new
  end

  def spawn_and_return_thread
    Thread.new do
      loop do
        break unless do_iteration

        break unless fetcher_has_time_left?
        Thread.pass
      end
    end
  end

  def write_data(data)
    data.each do |work_item_hash|
      item = work_item_hash[:work]
      @output_counter.increment
      if @seen_unique_ids[item.unique_id]
        @duplicate_output_counter.increment
      end
      @seen_unique_ids[item.unique_id] = item
      
      File.open(File.join(@configuration[:output_path],"#{item.unique_id}.yml"),"w") do |f|
        f.puts item.to_yaml
      end
      
    end
  end
  
end