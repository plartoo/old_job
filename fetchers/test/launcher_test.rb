require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/launcher'

class LaunchableFetcher
  def run
    #do nothing
  end
end

class LauncherTest < Test::Unit::TestCase

  def setup
    @thread_number = 1
    @fetchers = [
      {:name => "freepeople"},
      {:name => "freepeople2"}
    ]
    @launcher = Launcher.new
    @launcher.stubs(:fetchers).returns(@fetchers)
    @launcher.initialize_fetcher_queue

    @fetcher = LaunchableFetcher.new(:name => "freepeople",
                                     :run_after => Chronic.parse("2 minutes ago").strftime("%H:%M%p"),
                                     :launcher => @launcher)
  end

  def setup_fetcher_queue
    @launcher.stubs(:fetcher_queue).returns([@fetcher])
    @launcher.launch_fetcher
  end

  def test_pop_next_fetcher_removes_and_returns_next_fetcher
    expected = @launcher.fetcher_queue.first
    assert_equal expected, @launcher.pop_next_fetcher!
  end

  def test_pop_next_fetcher_returns_nil_if_nothing_in_queue
    setup_fetcher_queue
    @launcher.pop_next_fetcher!
    assert_nil @launcher.pop_next_fetcher!
  end

  def test_pop_next_fetcher_returns_second_fetcher_if_first_not_runnable
    setup_fetcher_queue

    fetcher_1 = mock("LaunchableFetcher")
    fetcher_1.stubs(:runnable?).returns(false,true)

    expected_first = @launcher.fetcher_queue.first
    @launcher.fetcher_queue.unshift(fetcher_1)
    puts @launcher.fetcher_queue
    assert_equal expected_first, @launcher.pop_next_fetcher!
    assert_equal fetcher_1,@launcher.pop_next_fetcher!
  end

  def test_queues_all_fetchers_to_run
    @launcher.initialize_fetcher_queue
    assert_equal ["freepeople", "freepeople2"], @launcher.fetcher_queue.map{|x| x.name}
  end

  def test_queues_all_fetchers_according_to_their_priority
    @prioritized_fetcher = [
      {:name => "freepeople"},
      {:name => "freepeople2", :priority=>1},
      {:name => "freepeople3", :priority=>2},
      {:name => "freepeople4", :priority=>1},
      {:lang=>"java", :bitmask_id=>60, :name=>"Javafetcher"},
      {:lang=>"java", :bitmask_id=>61, :name=>"Javafetcher2"},
      {:lang=>"java", :bitmask_id=>61, :name=>"Javafetcher3", :priority=>2}
    ]
    @launcher = Launcher.new
    @launcher.stubs(:fetchers).returns(@prioritized_fetcher)
    @launcher.initialize_fetcher_queue
    priority_array = @launcher.fetcher_queue.map{|x| x.priority || 0}
    check = nil
    priority_array.each_with_index do |priority,i|
      check = (priority >= (priority_array[i+1] || 0))
      assert check, "prioritizing fetcher has failed"
    end
  end

  def test_adds_fetchers_to_running_queue_respecting_concurrent_limit
    @launcher.stubs(:concurrent_running_limit).returns(1)
    @launcher.launch_fetcher
    @launcher.launch_fetcher
    assert_equal ["freepeople"], @launcher.running_queue.map{|x| x.name}
  end

  def test_launch_fetcher_runs_only_fetchers_that_are_runnable
    return if RUBY_PLATFORM =~ /mswin/
    fetcher = LaunchableFetcher.new(:name => "freepeople", :run_after => "8:35AM")
    @launcher.stubs(:fetcher_queue).returns([fetcher])
    fetcher.stubs(:runnable?).returns(false)
    @launcher.launch_fetcher
    assert_equal [], @launcher.running_queue
  end

  def test_runnable_respects_run_after
    fetcher = LaunchableFetcher.new(:name => "freepeople", :run_after => Chronic.parse("2 minutes ago").strftime("%H:%M%p"))
    assert_equal true, fetcher.runnable?

    fetcher = LaunchableFetcher.new(:name => "freepeople", :run_after => Chronic.parse("2 minutes from now").strftime("%H:%M%p"))
    assert_equal false, fetcher.runnable?
  end

  def test_launch_fetcher_runs_first_fetcher_in_fetcher_queue
    return if RUBY_PLATFORM =~ /mswin/
    fetcher = LaunchableFetcher.new(:name => "freepeople",
                                    :run_after => Chronic.parse("2 minutes ago").strftime("%H:%M%p"),
                                    :launcher => @launcher)
    @launcher.stubs(:fetcher_queue).returns([fetcher])
    fetcher.expects(:launch).once
    @launcher.launch_fetcher
  end

  def test_launch_fetcher_records_start_time
    setup_fetcher_queue
    assert_not_nil @fetcher.start_time
  end

  def test_run_fetcher_launches_fetcher_with_threaded_not_set
    @fetcher = LaunchableFetcher.new(:name => "freepeople",
                                     :run_after => Chronic.parse("2 minutes ago").strftime("%H:%M%p"),
                                     :launcher => @launcher)
    expected_command = "rake fetch "
    expected_command << "FEED_PATH=/usr/local/salemail/yaml_feeds "
    expected_command << "I18N_VERSION=us "
    expected_command << "THREADED=false "
    expected_command << "TIME_LIMIT_IN_MINS=#{@launcher.configuration[:fetcher_running_time_limit_in_minutes]} "
    expected_command << "VENDOR_CLASS=Freepeople "
    expected_command << "VENDOR_PATH=freepeople"
    @fetcher.expects(:execute).with(expected_command)
    @fetcher.run_fetcher_rake_task
  end

  def test_run_fetcher_launches_fetcher_with_threaded_set_to_true
    @fetcher = LaunchableFetcher.new(:name => "freepeople",:threaded => true,
                                     :run_after => Chronic.parse("2 minutes ago").strftime("%H:%M%p"),
                                     :launcher => @launcher)
    expected_command = "rake fetch "
    expected_command << "FEED_PATH=/usr/local/salemail/yaml_feeds "
    expected_command << "I18N_VERSION=us "
    expected_command << "NUM_ITEM_SCRAPER_THREADS=1 "
    expected_command << "NUM_SCCS_THREADS=1 "
    expected_command << "THREADED=true "
    expected_command << "TIME_LIMIT_IN_MINS=#{@launcher.configuration[:fetcher_running_time_limit_in_minutes]} "
    expected_command << "VENDOR_CLASS=Freepeople "
    expected_command << "VENDOR_PATH=freepeople"
    @fetcher.expects(:execute).with(expected_command)
    @fetcher.run_fetcher_rake_task
  end

  def test_launchable_fetcher_records_time_limit_when_provided
    launcher = Launcher.new
    fetcher = LaunchableFetcher.new(:name => "freepeople",
                                     :time_limit => 1234,
                                     :run_after => Chronic.parse("2 minutes ago").strftime("%H:%M%p"),
                                     :launcher => launcher)
    launcher.stubs(:fetcher_queue).returns([@fetcher])
    launcher.launch_fetcher
    assert_equal 1234, fetcher.time_limit
  end

  def test_run_fetcher_launches_fetcher_with_time_limit_when_provided
    launcher = Launcher.new
    fetcher = LaunchableFetcher.new(:name => "freepeople",
                                     :time_limit => 1234,
                                     :run_after => Chronic.parse("2 minutes ago").strftime("%H:%M%p"),
                                     :launcher => launcher)
    expected_command = "rake fetch "
    expected_command << "FEED_PATH=/usr/local/salemail/yaml_feeds "
    expected_command << "I18N_VERSION=us "
    expected_command << "THREADED=false "
    expected_command << "TIME_LIMIT_IN_MINS=#{fetcher.time_limit} "
    expected_command << "VENDOR_CLASS=Freepeople "
    expected_command << "VENDOR_PATH=freepeople"
    fetcher.expects(:execute).with(expected_command)
    fetcher.run_fetcher_rake_task
  end

  def test_remove_completed_fetchers_doesnt_remove_uncompleted_fetechers
    setup_fetcher_queue
    @fetcher.stubs(:completed?).returns(false)
    @launcher.remove_fetchers :completed
    assert_equal [@fetcher], @launcher.running_queue
  end

  def test_remove_completed_fetchers_removes_completed_fetchers_and_queues_import
    setup_fetcher_queue
    @fetcher.stubs(:completed?).returns(true)
    @launcher.import_queue.expects(:<<).with(@fetcher)
    @launcher.remove_fetchers :completed
    assert_equal [], @launcher.running_queue
  end

  def test_import_a_fetcher_runs_after_completed_on_popped_fetcher
    @launcher.import_queue << @fetcher
    expected_command = "cd #{@launcher.configuration[:import_base_dir]} && "
    expected_command << "rake yaml_clothing_items:import DATE=#{Time.now.strftime('%y%m%d')} "
    expected_command << "FEED=#{@fetcher.feed_dir_for_import} "
    expected_command << "I18N_VERSION=us "
    expected_command << "RAILS_ENV= "
    expected_command << "VENDOR=freepeople"
    @fetcher.expects(:execute).with(expected_command)
    @launcher.import_a_fetcher
  end

  def test_import_a_fetcher_rescues_error_if_nothing_to_pop
    @launcher.import_queue.clear
    assert_nothing_raised do
      @launcher.import_a_fetcher
    end
  end

  def test_fetching_completed_returns_true_if_flag_is_set
    @launcher.fetching_completed = true
    assert @launcher.fetching_completed?
  end

  def test_fetching_completed_returns_false_when_flag_not_set
    @launcher.fetching_completed = false
    assert !@launcher.fetching_completed?
  end

  def test_run_import_thread_iterates_when_queue_empty_but_fetching_not_completed
    @launcher.stubs(:fetching_completed?).returns(false).returns(true)
    @launcher.import_queue.clear
    @launcher.expects(:import_a_fetcher).once
    @launcher.run_import_thread(@thread_number)
  end

  def test_run_import_thread_iterates_when_queue_not_empty_but_fetching_completed
    @launcher.fetching_completed = true
    @launcher.import_queue.clear
    @fetcher.expects(:after_completed).returns(nil)
    @launcher.import_queue << @fetcher
    @launcher.run_import_thread(@thread_number)
  end

  def test_run_import_thread_breaks_when_queue_empty_and_fetching_completed
    @launcher.stubs(:fetching_completed?).returns(true)
    @launcher.import_queue.clear
    @launcher.expects(:import_a_fetcher).never
    @launcher.run_import_thread(@thread_number)
  end

  def test_initialize_import_thread_pushes_on_thread_that_calls_run_import_thread
    @launcher.threads = []
    @launcher.expects(:run_import_thread).returns(nil)
    @launcher.initialize_import_thread
    assert @launcher.threads.first.is_a?(Thread)
    @launcher.threads.first.join
  end

  def test_remove_expired_doesnt_remove_unexpired_fetchers
    setup_fetcher_queue
    @fetcher.stubs(:expired?).returns(false)
    @launcher.remove_fetchers :expired
    assert_equal [@fetcher], @launcher.running_queue
  end

  def test_remove_expired_removes_expireds_fetchers
    setup_fetcher_queue
    @fetcher.stubs(:expired?).returns(true)
    @fetcher.stubs(:after_expired)
    @launcher.remove_fetchers :expired
    assert_equal [], @launcher.running_queue
  end

  def test_remove_expired_fetchers_calls_after_expired
    setup_fetcher_queue
    @fetcher.stubs(:expired?).returns(true)
    @fetcher.expects(:after_expired)
    @launcher.remove_fetchers :expired
  end

  def test_after_expired_calls_after_expired_and_queues_fetcher_for_import
    setup_fetcher_queue
    @fetcher.stubs(:expired?).returns(true)
    @fetcher.expects(:after_expired)
    @launcher.import_queue.expects(:<<).with(@fetcher)
    @launcher.remove_fetchers :expired
  end

  def test_expired_compares_running_time_with_configuration
    setup_fetcher_queue
    @launcher.stubs(:configuration).returns({:fetcher_running_time_limit_in_minutes => 5})
    @fetcher.stubs(:start_time).returns(Chronic.parse("3 minutes ago"))
    assert_equal false, @fetcher.expired?
    @fetcher.stubs(:start_time).returns(Chronic.parse("6 minutes ago"))
    assert_equal true, @fetcher.expired?
  end

  def test_first_class_name_defined_returns_first_class_name
    s = <<-EOS
      #foo bar comment
      non-comment
      class Foobar < Barfoo

      end
    EOS
    assert_equal "Foobar", LaunchableFetcher.first_class_name_defined(s)
  end

  def configuration
    {
      :default => {
        :fetcher_running_time_limit_in_minutes => 180,
        :concurrent_running_limit => 18,
        :feed_dir => "/usr/local/salemail/yaml_feeds"
      },
      :staging => {
        :concurrent_running_limit => 10
      }
    }.dup
  end

  def fetchers_configuration
    {
      :fetchers => [
        {
          :run_after => nil,
          :name => "asos"
        }
      ]
    }.dup
  end

  def test_configuration_uses_RAILS_ENV_to_lookup_correct_configuration
    return if RUBY_PLATFORM =~ /mswin/
    @launcher.expects(:load_configuration_from_file).with("./../lib/../config/launcher.yml").returns(configuration)
    @launcher.expects(:load_configuration_from_file).with("./../lib/../config/launcher.us.yml").returns(fetchers_configuration)
    @launcher.instance_variable_set('@env', 'staging')

    @launcher.load_configuration
    assert_equal 10, @launcher.configuration[:concurrent_running_limit]
    assert_equal 180, @launcher.configuration[:fetcher_running_time_limit_in_minutes]
    assert_equal fetchers_configuration[:fetchers], @launcher.configuration[:fetchers]
  end

  def test_configuration_uses_RAILS_ENV_to_lookup_correct_configuration_when_RAILS_ENV_is_nil
    return if RUBY_PLATFORM =~ /mswin/
    @launcher.expects(:load_configuration_from_file).with("./../lib/../config/launcher.yml").returns(configuration)
    @launcher.expects(:load_configuration_from_file).with("./../lib/../config/launcher.us.yml").returns(fetchers_configuration)

    @launcher.load_configuration
    assert_equal 18, @launcher.configuration[:concurrent_running_limit]
    assert_equal 180, @launcher.configuration[:fetcher_running_time_limit_in_minutes]
    assert_equal fetchers_configuration[:fetchers], @launcher.configuration[:fetchers]
  end

  def test_launcher_loads_fetchers_correctly_for_different_environment
    return if RUBY_PLATFORM =~ /mswin/
    @launcher = Launcher.new
    @launcher.instance_variable_set('@env', 'staging')
    staging_env_fetchers = @launcher.load_configuration_from_file(File.join(File.dirname(__FILE__), "..", "config", "launcher.#{@launcher.i18n_version}.yml"))
    staging_env_fetchers = staging_env_fetchers[:fetchers].collect{|x| x[:name]}
    @launcher.instance_variable_set('@env', 'fb')
    production_env_fetchers = @launcher.load_configuration_from_file(File.join(File.dirname(__FILE__), "..", "config", "launcher.#{@launcher.i18n_version}.yml"))
    production_env_fetchers = production_env_fetchers[:fetchers].collect{|x| x[:name]}
    assert_equal staging_env_fetchers.size, staging_env_fetchers.uniq.size
    assert_equal production_env_fetchers.size, production_env_fetchers.uniq.size
  end

  def test_prepare_fetchers_sets_threaded_key_if_force_threaded_framework_flag_is_true
    setup_fetcher_queue
    launcher = Launcher.new('us',true)
    launcher.stubs(:fetchers).returns(@fetchers)
    launcher.initialize_fetcher_queue
    launcher.prepare_fetchers
    assert launcher.configuration[:fetchers].first[:threaded]
  end

  def test_prepare_fetchers_does_not_set_threaded_key_if_force_threaded_framework_flag_is_false
    setup_fetcher_queue
    launcher = Launcher.new('us',false)
    launcher.prepare_fetchers
    assert !launcher.configuration[:fetchers].first[:threaded]
  end

end
