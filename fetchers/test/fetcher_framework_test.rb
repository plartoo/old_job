require 'test_helper'

require File.dirname(__FILE__)+"/../lib/fetcher_framework"

class FetcherFrameworkTest < Test::Unit::TestCase

  def setup
    @fetcher_name = "victoriassecret"
    @fetcher_class = Victoriassecret
    Victoriassecret.log = Logger.new(STDOUT)
    @config = {:fetcher_name => @fetcher_name, :i18n_version => 'us', :fetcher_class_name => "Victoriassecret"}
    @framework = FetcherFramework.new(@config)

  end

  def test_initialize_sets_instance_variables_of_hash_param_data
    @config.each do |k,v|
      assert_equal v, @framework.instance_variable_get("@#{k}")
    end
  end

  def test_initialize_raises_error_on_nil_i18n_version
    assert_raise FetcherFramework::InvalidParameters do
      FetcherFramework.new({})
    end
  end

  def test_cleanup_runs_close_on_stream_if_should
    @framework.html_uncat_file = true
    @framework.fetcher_class = @fetcher_class
    @framework.uncategorized_output_stream.stubs(:close)
    @framework.cleanup(true)
  end

  def test_cleanup_doesnt_call_close_if_not_html_log_uncat
    @framework.html_uncat_file = false
    @framework.uncategorized_output_stream.stubs(:close).times(0)
    @framework.fetcher_class = @fetcher_class
    @framework.cleanup(true)
  end

  def test_cleanup_doesnt_call_close_if_not_output_stream
    @framework.html_uncat_file = true
    @framework.uncategorized_output_stream = nil
    @framework.fetcher_class = @fetcher_class
    assert_nothing_raised do
      @framework.cleanup(true)
    end
  end

  def test_grab_options_returns_time_limit_keys_if_time_limit_in_mins_is_set
    @framework.time_limit_in_mins = 10
    fake_start_epoch = 0
    returned = @framework.grab_options(fake_start_epoch)
    assert_equal 8*60, returned[:time_limit_in_seconds]
    assert_equal 10 - 2, returned[:time_limit_in_mins]
    assert_equal fake_start_epoch + 8*60, returned[:time_to_stop]
  end

  def test_grab_options_returns_no_time_limit_keys_set_if_time_limit_in_mins_is_nil
    @framework.time_limit_in_mins = nil
    fake_start_epoch = 0
    returned = @framework.grab_options(fake_start_epoch)
    assert_nil returned[:time_limit_in_seconds]
    assert_nil returned[:time_limit_in_mins]
    assert_nil returned[:time_to_stop]
  end

  def test_grab_categories_rescues_error_if_get_categories_errors
    @framework.fetcher = mock(@fetcher_class_name) do
      expects(:get_categories).raises(StandardError)
      expects(:log).returns(Logger.new(STDOUT)).twice
    end
    assert_nothing_raised do
      @framework.grab_categories
    end
  end

  def test_grab_categories_returns_the_result_from_get_categories
    expected = "expected result"
    @framework.fetcher = mock("Fetcher") do
      expects(:get_categories).returns(expected)
    end
    assert_equal expected, @framework.grab_categories
  end

  def test_grab_coupons_returns_the_result_from_get_coupons
    expected = ["expected result"]
    @framework.fetcher_class = @fetcher_class
    @fetcher_class.stubs(:get_coupons).returns(expected)
    assert_equal expected, @framework.grab_coupons
  end

  def test_grab_coupons_returns_empty_array_if_nil_coupons
    @framework.fetcher_class = @fetcher_class
    @fetcher_class.stubs(:get_coupons).returns(nil)

    assert_equal [], @framework.grab_coupons
  end

  def test_configure_and_return_fetcher_returns_fetcher_object_with_proper_name_and_module
    require File.dirname(__FILE__)+"/../fetchers/#{@fetcher_name}/#{@fetcher_name}"
    result = @framework.spawn_and_configure_fetcher
    assert result.is_a?(Victoriassecret)
  end

  def test_configure_and_return_fetcher_raises_error_if_FetcherHelperMethods_spawn_errors
    FetcherHelperMethods.stubs(:spawn_new_fetcher_instance).raises(StandardError)
    assert_raise StandardError do
      @framework.spawn_and_configure_fetcher
    end
  end

  def test_create_framework_obj_returns_MT_framework_given_multithread_symbol
    assert FetcherFramework.create_framework_obj({:i18n_version => 'us'},:multithread).is_a?(MultithreadFramework)
  end

  def test_create_framework_obj_returns_ST_framework_given_singlethread_symbol
    assert FetcherFramework.create_framework_obj({:i18n_version => 'us'},:singlethread).is_a?(SinglethreadFramework)
  end

  def test_create_framework_obj_returns_AC_framework_given_assisted_checkout_symbol
    assert FetcherFramework.create_framework_obj({:i18n_version => 'us'},:assisted_checkout).is_a?(AssistedCheckoutFramework)
  end

  def test_run_raises_error
    assert_raise(RuntimeError) do
      @framework.run
    end
  end

  def test_time_run_out_returns_true_if_time_run_out
    @framework.options = {:time_to_stop => 1}
    assert @framework.time_run_out?(2)
  end

  def test_time_run_out_returns_false_if_no_limit_set
    @framework.options = {:time_to_stop => nil}
    assert !@framework.time_run_out?("anything")
  end

  def test_time_run_out_returns_false_limit_set_but_not_met
    @framework.options = {:time_to_stop => 2}
    assert !@framework.time_run_out?(1)
  end

end
