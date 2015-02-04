require 'digest'

class LaunchableFetcher
  attr_reader :name, :lang, :bitmask_id, :priority, :num_sccs_threads, :num_item_scraper_threads
  attr_accessor :child_process_uid, :start_time, :time_limit, :threaded

  def initialize(attributes)
    @name = attributes[:name]
    @lang = attributes[:lang]
    @bitmask_id = attributes[:bitmask_id]
    @run_after = Chronic.parse(attributes[:run_after])
    @launcher = attributes[:launcher]
    @priority = attributes[:priority]
    @threaded = attributes[:threaded]
    @num_sccs_threads = attributes[:num_sccs_threads] || 1
    @num_item_scraper_threads = attributes[:num_item_scraper_threads] || 1
    @time_limit = attributes[:time_limit]
  end

  def runnable?
    @run_after.nil? || @run_after < Time.now
  end

  def launch
    self.start_time = Time.now
    exit_code = self.run_fetcher_rake_task
    self.completed = exit_code 
  rescue Exception=>e
    puts "EXCEPTION: #{e.inspect}"
  end

  def run_fetcher_rake_task
    rake_options = {}
    rake_options["VENDOR_CLASS"] = self.class_name
    rake_options["I18N_VERSION"] = @launcher.i18n_version
    rake_options["TIME_LIMIT_IN_MINS"] = @time_limit || @launcher.configuration[:fetcher_running_time_limit_in_minutes]
    rake_options["FEED_PATH"] = self.feed_dir
    rake_options["VENDOR_PATH"] = self.name
    rake_options["THREADED"] = self.threaded || "false"
    if self.threaded
      rake_options["NUM_SCCS_THREADS"] = self.num_sccs_threads
      rake_options["NUM_ITEM_SCRAPER_THREADS"] = self.num_item_scraper_threads
    end
    rake_options = rake_options.to_a.sort.map{|k,v| "#{k}=#{v}"}.join(" ")
    cmd = "rake fetch #{rake_options}"
    run_command_and_log_results(cmd, "Starting #{self.name}")
  end

  def class_name
    class_name = File.open(File.dirname(__FILE__) + "/../fetchers/#{self.name}/#{self.name}.rb") do |x|
      LaunchableFetcher.first_class_name_defined x.readlines
    end
  end

  def completed=(status)
    @completed = status
    @launcher.logger.info "Completed #{self.name} (completed status=#{@completed})"
  end

  def completed?
    @completed
  end

  def success?
    @completed && @completed.success?
  end

  def after_completed
    rake_options = {}
    rake_options["FEED"] = self.feed_dir_for_import
    rake_options["VENDOR"] = self.name
    rake_options["I18N_VERSION"] = @launcher.i18n_version
    rake_options["RAILS_ENV"] = self.rails_env
    rake_options["DATE"] = Time.now.strftime("%y%m%d")
    rake_options = rake_options.to_a.sort.map{|k,v| "#{k}=#{v}"}.join(" ")
    cmd = "cd #{@launcher.configuration[:import_base_dir]} && rake yaml_clothing_items:import #{rake_options}"
    #@launcher.logger.info "Skipping import: #{cmd}"
    run_command_and_log_results(cmd, "Importing #{self.name}")
    @launcher.logger.info "Importing finished: #{self.name}"
  end

  def rails_env
    ENV['RAILS_ENV']
  end

  def feed_dir
    if @launcher.configuration[:feed_dir]
      @launcher.configuration[:feed_dir]
    else
     File.expand_path(File.join(File.dirname(__FILE__),"..", 'yaml_feeds', @launcher.i18n_version))
    end
  end

  def feed_dir_for_import
    @launcher.configuration[:feed_dir] || File.expand_path(File.join(File.dirname(__FILE__),"..",'yaml_feeds',@launcher.i18n_version))
  end

  def run_command_and_log_results(cmd, msg)
    result = self.execute(cmd,msg) || ""
    result.each_line do |line|
      @launcher.logger.info "[#{self.name}] result: #{line.chomp}"
    end
    $CHILD_STATUS
  end

  def on_windows?
    RUBY_PLATFORM=~/ming|win/
  end

  # execute - assumes cmd is a rake task so we can append 'IDENTIFIER=<random>' to make this killable via pkill
  def execute(cmd,msg)
    identify_string = unless on_windows?
                        self.child_process_uid = Digest::SHA1.hexdigest(Time.now.to_s + cmd)
                        "IDENTIFIER=#{child_process_uid}"
                      else ''
                      end
    real_cmd = "#{cmd} #{identify_string} 2>&1"
    @launcher.logger.info "#{msg} with #{real_cmd}"
    `#{real_cmd}`
  end

  def expired?
    self.start_time && Time.now > self.start_time + @launcher.configuration[:fetcher_running_time_limit_in_minutes].minutes
  end

  def after_expired
    raise "Trying to expire an unlaunched fetcher or on windows" unless self.child_process_uid

    `pkill -9 -f #{child_process_uid}`
    @launcher.logger.info "Expired #{self.name}"
  end

  def set_time_limit_to(value)
    @time_limit = value
  end

  def self.first_class_name_defined(lines)
    result = nil
    lines.find{|line| result = line.strip[/class\s(\w+)/, 1]}
    result
  end
end
