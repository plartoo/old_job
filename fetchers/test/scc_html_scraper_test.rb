require File.dirname(__FILE__) + '/test_helper'

class SCCHtmlScraperTest < Test::Unit::TestCase

  def setup
    Victoriassecret.log = Logger.new(STDOUT)
  end

  def test_scrape_with_first_option_invalid_size
    item = setup_item
    sccs = sccs_with_first_option
    sccs = sccs.scrape({:item => item})
    assert_equal(expected_sccs, sccs)
  end

  def test_scrape_with_skip_first_option_invalid_size_does_not_log_message
    item = setup_item
    sccs = sccs_with_first_option(:skip_first => true)
    sccs = sccs.scrape({:item => item})
    assert_equal(expected_sccs, sccs)
  end

  def setup_item(filename = 'item_page_for_html_scrape.html')
    url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'html', filename))
    item = Item.new
    item.product_url = url
    item.dept = :womens
    item.clothing_type = ClothingType[:CASUAL_SHIRT,item.dept]
    item
  end

  def sccs_with_first_option(options = {})
    SCCFromHTMLScraper.new(Victoriassecret) do
      size options do
        is 'option'
        ancestor do
          is 'select'
          with :id => 'select'
        end
      end

      color :no_color => true do |item|
      end
    end
  end

  def expected_sccs
    [
      {:color=>"", :size_bm=>1, :size_type_bm=>0},
      {:color=>"", :size_bm=>2, :size_type_bm=>0},
      {:color=>"", :size_bm=>3, :size_type_bm=>0}
    ]
  end

end