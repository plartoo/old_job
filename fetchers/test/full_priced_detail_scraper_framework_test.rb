require File.dirname(__FILE__) + '/test_helper'
require 'full_priced_detail_scraper_framework'

class FullPricedDetailScraperFrameworkTest < Test::Unit::TestCase

  def setup
    @fetcher_name = "victoriassecret"
    @fetcher_class_name = "Victoriassecret"
    @options = {:fetcher_name => @fetcher_name, :i18n_version => 'us', :fetcher_class_name => @fetcher_class_name}
    @framework = FullPricedDetailScraperFramework.new(@options)
  end

  def test_configure_and_return_fetcher_calls_load_fetcher_file_if_has_been_memoized_and_returns_memoized_object
    expected = Victoriassecret.new
    FullPricedDetailScraperFramework.fetcher_objects[@fetcher_name] = expected
    assert_equal expected, @framework.spawn_and_configure_fetcher
  end

  def test_configure_and_return_fetcher_calls_spawn_new_fetcher_instance_and_memoizes_result
    expected = Victoriassecret.new
    FullPricedDetailScraperFramework.fetcher_objects[@fetcher_name] = nil
    FetcherHelperMethods.expects(:spawn_new_fetcher_instance).returns(expected)
    @framework.stubs(:create_logger).returns(nil)
    assert_equal expected, @framework.spawn_and_configure_fetcher
    assert_equal expected, FullPricedDetailScraperFramework.fetcher_objects[@fetcher_name]
  end

end
