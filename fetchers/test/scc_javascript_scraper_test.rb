require 'test_helper'

class SCCFromJavaScriptScraperTest < Test::Unit::TestCase

  def test_scrape
    sccs = SCCFromJavaScriptScraper.new(Victoriassecret) do
      testing
      pattern /.*itemMap\[\d\] = \{.*,sDesc: "(.+)",.*,cDesc: "(.+)",.*,avail: "IN_STOCK".*/
      mappings :size => 1, :color => 2
    end

    item = Item.new
    item.product_url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'html', 'detail_page_for_scc_javascript_scraper.html'))
    item.dept = :womens
    item.clothing_type = ClothingType[:DRESS,item.dept]
    sccs = sccs.scrape({:item => item})

    assert_equal(7, sccs.size, "size")

    expected = [
                {:size => "L", :color => "clotted cream"},
                {:size => "L", :color => "geranium"},
                {:size => "M", :color => "geranium"},
                {:size => "S", :color => "geranium"},
                {:size => "XS", :color => "geranium"},
                {:size => "L", :color => "navy"},
                {:size => "S", :color => "navy"}
                ]

    expected.each do |ex|
      assert_equal(true, sccs.include?(ex), ex.to_s)
    end                
  end

  def test_all_size_duplication
    sccs = SCCFromJavaScriptScraper.new(Victoriassecret) do
      pattern /.*itemMap\[\d+\] = \{.*,sDesc: "(.+)",.*,cDesc: "(.+)",.*,avail: "IN_STOCK".*/
      mappings :size => 1, :color => 2
    end

    item = Item.new
    item.product_url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'html', 'detail_page_for_scc_javascript_scraper_duplication.html'))
    item.dept = :womens
    item.clothing_type = ClothingType[:BAG,item.dept]
    sccs = sccs.scrape({:item => item})

    assert_equal(1, sccs.size, "size")
  end

  def test_multiple_size_matching
    sccs = SCCFromJavaScriptScraper.new(Victoriassecret) do
      pattern /.*itemMap\[\d+\] = \{.*,sDesc: "(.+)",.*,cDesc: "(.+)",.*,avail: "IN_STOCK".*/
      mappings :size => 1, :color => 2

      matchers "8" => ["S", "M"], "9" => ["L", "XL"]
    end
   
    item = Item.new
    item.product_url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'html', 'detail_page_for_scc_javascript_scraper_duplication.html'))
    item.dept = :womens
    item.clothing_type = ClothingType[:DRESS,item.dept]
    sccs = sccs.scrape({:item => item})
    expected = [{:color=>"geranium", :size_type_bm=>2, :size_bm=>1},
                {:color=>"geranium", :size_type_bm=>2, :size_bm=>2},
                {:color=>"geranium", :size_type_bm=>2, :size_bm=>3},
                {:color=>"geranium", :size_type_bm=>2, :size_bm=>4}]
    assert_equal(expected, sccs)
  end

end
