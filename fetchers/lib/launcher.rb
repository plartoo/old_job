require 'yaml'
require 'forwardable'
require 'chronic'
require 'activesupport'
require 'win32/process' if RUBY_PLATFORM =~ /win32/
require 'English'
require 'erb'

require File.dirname(__FILE__)+"/launchable_fetcher"

class Launcher

  attr_reader :configuration, :i18n_version, :logger, :env, :force_threaded_framework
  attr_accessor :import_queue, :fetching_completed, :threads

  def initialize(i18n_version = "us", force_threaded_framework = false)
    @i18n_version = i18n_version
    @fetcher_queue = Array.new
    @running_queue = Array.new
    Dir.mkdir File.join(File.dirname(__FILE__),"..", "log") unless File.exists? File.join(File.dirname(__FILE__),"..", "log")
    @logger = Logger.new(File.join(File.dirname(__FILE__),"..", "log", "launcher.log"))
    @logger.formatter = SeverityFormatter.new
    @threads = []
    @env = ENV['RAILS_ENV']
    @force_threaded_framework = force_threaded_framework
    @import_queue = Queue.new
    @fetching_completed = false
    load_configuration
    prepare_fetchers
  end

  def load_configuration
    config = load_configuration_from_file(File.join(File.dirname(__FILE__),"..", "config", "launcher.yml"))
    if env.nil?
      @configuration = config[:default] || {}
    else
      @configuration = (config[:default] || {}).merge(config[env.to_sym] || {})
    end
    @configuration.merge!(load_configuration_from_file(File.join(File.dirname(__FILE__),"..", "config", "launcher.#{self.i18n_version}.yml")))
  end

  def prepare_fetchers
    if @force_threaded_framework
      @configuration[:fetchers].each do |fetcher|
        fetcher[:threaded] = true
      end
    end
  end

  def load_configuration_from_file(file)
    YAML.load(ERB.new(IO.read(file)).result(binding))
  end

  def run
    self.initialize_fetcher_queue
    initialize_import_thread
    while self.fetcher_queue.any? || self.running_queue.any?
      launch_fetcher
      remove_fetchers :expired
      remove_fetchers :completed
      sleep 1
    end

    ## All fetchers are pushed onto import queue by this time. Solves race condition.
    @fetching_completed = true
    
    self.logger.info "joining threads"
    @threads.each{|t| t.join}
  end

  def initialize_import_thread
    num_import_threads.times do |i|
      @threads << Thread.new do
        run_import_thread i
      end
    end
  end

  def remove_fetchers(expired_or_completed)
    raise ArgumentError unless [:expired, :completed].include?(expired_or_completed)
    of_interest = @running_queue.select{|x| x.send("#{expired_or_completed}?")}
    of_interest.each do |fetcher|
      @running_queue.delete(fetcher)
      fetcher.after_expired if :expired == expired_or_completed
      
      @import_queue << fetcher
    end
  end

  def pop_next_fetcher!
     next_fetcher_index = nil

     self.fetcher_queue.each_with_index do |fetcher,index|
       if fetcher && fetcher.runnable?
         next_fetcher_index = index
         break
       end
     end

     next_fetcher = next_fetcher_index ? self.fetcher_queue.delete_at(next_fetcher_index) : nil

     next_fetcher
   end

   def launch_fetcher
     if self.running_queue.length < self.concurrent_running_limit
       if fetcher = self.pop_next_fetcher!
         self.running_queue << fetcher
         @threads << Thread.new do
           fetcher.launch
         end
       end
     end
   end

  def initialize_fetcher_queue
    prioritized_fetchers = self.fetchers.select{|x| x.has_key?(:priority)}.sort{|x,y| x[:priority] <=> y[:priority]}.reverse
    non_prioritized_fetchers = self.fetchers.select{|x| !x.has_key?(:priority)}
    all_fetchers = prioritized_fetchers | non_prioritized_fetchers
    @fetcher_queue = all_fetchers.map{|x| LaunchableFetcher.new(x.merge({:launcher => self}))}
  end

  def run_import_thread(thread_number)
    self.logger.info "Starting import thread #{thread_number}"

    until fetching_completed? && @import_queue.empty?
      import_a_fetcher

      sleep 1
    end
    
    self.logger.info "Terminating import thread"
  end

  NON_BLOCK = true
  def import_a_fetcher
    return if @import_queue.empty?

    fetcher = @import_queue.pop(NON_BLOCK)
    fetcher.after_completed
  rescue ThreadError => empty_queue_error
    self.logger.info "import thread fetched from empty queue #{empty_queue_error.inspect}. Likely just because we are running multiple import threads and to be expected occasionally"
  end

  def run_and_import_one_fetcher(fetcher_name, time_limit=nil)
    fetcher = self.fetchers.select{|x| x[:name].eql?(fetcher_name)}
    if fetcher.size == 1
      launchable_fetcher = LaunchableFetcher.new(fetcher.first.merge({:launcher => self}))
      launchable_fetcher.set_time_limit_to(time_limit) unless time_limit.nil?
      launchable_fetcher.launch if !launchable_fetcher.nil? && launchable_fetcher.runnable?
    else
      self.logger.error "provided fetcher_name is invalid"
    end
    launchable_fetcher.after_completed
  end

  def fetching_completed?
    @fetching_completed == true
  end

  def fetchers
    @configuration[:fetchers]
  end

  def fetcher_queue
    @fetcher_queue
  end

  def running_queue
    @running_queue
  end

  def num_import_threads
    @configuration[:num_import_threads]
  end

  def concurrent_running_limit
    @configuration[:concurrent_running_limit]
  end

  def staging?
    "staging" == @env
  end

  def production?
    "fb" == @env
  end
end

class SeverityFormatter < Logger::Formatter
  def call(severity, timestamp, progname, msg)
    "#{timestamp}: [#{Process.pid}/#{Thread.current.object_id.to_s(16)}] #{msg}\n"
  end
end
