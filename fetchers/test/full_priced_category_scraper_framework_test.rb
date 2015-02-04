require File.dirname(__FILE__) + '/test_helper'
require 'full_priced_category_scraper_framework'

class FullPricedCategoryScraperFrameworkTest < Test::Unit::TestCase

  def setup
    @fetcher_name = "all_saints"
    @fetcher_module_name = "AllSaints"
    @options = {:fetcher_name => @fetcher_name, :i18n_version => 'us', :fetcher_module_name => @fetcher_module_name}
    @framework = FullPricedCategoryScraperFramework.new(@options)
  end

  def test_move_batches_from_to_calls_right_commands
    file_chars = (0..9).entries + ("a".."f").entries
    from = "from"
    to = "to"
    @framework.stubs(:run_cmd).returns(nil)
    file_chars.each do |char|
      @framework.stubs(:run_cmd).with("mv #{from}/#{char}* #{to}/")
    end
    @framework.move_batches_from_to(from,to)
  end

end
