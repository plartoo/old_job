require File.dirname(__FILE__) + '/test_helper'

class SCCCustomScraperTest < Test::Unit::TestCase

  def setup
    @url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'html', 'detail_page_for_custom_scraper.html'))
    @item = Item.new
    @item.product_url = @url
    @item.dept = :womens
    @item.clothing_type = ClothingType[:CASUAL_SHIRT,@item.dept]
  end

  def test_scrape
    sccs = SCCCustomScraper.new(Victoriassecret) do
      testing
      all_at_once

      give_me do
        is 'script'
      end

      process do |script|
        sccs = nil
        content = script.child.to_s
        if content.index("new objColor")
          content = content.slice(content.index("new objColor"), content.size)
          lines = content.split("\n")
          sccs = []
          color = nil
          lines.each do |line|
            if line.index("objColor")
              color = /\('\d+','\d+','(.*?)',/.match(line)[1]
            elsif line.index("AddSize")
              size = /AddSize\('(.*?)',/.match(line)[1]
              sccs << [size, color]
            end
          end
        end
        sccs
      end
    end
    
    sccs = sccs.scrape({:item => @item})
   
    expected_sccs = [{:color=>"Navy Lace", :size=>"0"},
                     {:color=>"Navy Lace", :size=>"2"},
                     {:color=>"Navy Lace", :size=>"4"},
                     {:color=>"Navy Lace", :size=>"6"},
                     {:color=>"Navy Lace", :size=>"8"},
                     {:color=>"Navy Lace", :size=>"10"},
                     {:color=>"Navy Lace", :size=>"12"},
                     {:color=>"Navy Lace", :size=>"14"}]

    assert_equal(expected_sccs, sccs)
  end

  def test_makes_item_available_as_method
    @item.expects(:call_me)
    sccs = SCCCustomScraper.new(Victoriassecret) do
      item.call_me
    end
    sccs.scrape({:item => @item})
  end

  def test_sccs_custom_scraper_handles_hash_of_items
    sccs = SCCCustomScraper.new(Victoriassecret) do
      testing
      all_at_once

      give_me do
        is 'script'
      end

      process do |script|
        item = Item.new()
        item.dept = :womens
        item.clothing_type={:bm=>1, :group=>:bottom}
        item.scc = [{:size=>"XL",:color=>"White"},{:size=>"L",:color=>"Black"}]
        {:all_items=>[item]}
      end
    end
    expected_item = Item.new()
    expected_item.dept = :womens
    expected_item.clothing_type={:bm=>1, :group=>:bottom}
    expected_item.scc = [{:size_bm=>4, :color=>"White", :size_type_bm=>2},
      {:size_bm=>3, :color=>"Black", :size_type_bm=>2}]

    return_data = sccs.scrape({:item => @item})
    assert_equal Array, return_data[:all_items].class
    assert_equal 1, return_data[:all_items].size
    assert_equal expected_item.scc, return_data[:all_items].first.scc
  end


  def test_sccs_custom_scraper_removes_invalid_sccs_from_hash_of_items
    sccs = SCCCustomScraper.new(Victoriassecret) do
      testing
      all_at_once

      give_me do
        is 'script'
      end

      process do |script|
        item = Item.new()
        item.dept = :womens
        item.clothing_type={:bm=>1, :group=>:bottom}
        item.scc = [{:size=>"INVALIDSIZE",:color=>"White"},{:size=>"L",:color=>"Black"}]

        {:all_items=>[item]}
      end
    end
    expected_item = Item.new()
    expected_item.dept = :womens
    expected_item.clothing_type={:bm=>1, :group=>:bottom}
    expected_item.scc = [{:size_bm=>3, :color=>"Black", :size_type_bm=>2}]

    return_data = sccs.scrape({:item => @item})
    assert_equal Array, return_data[:all_items].class
    assert_equal 1, return_data[:all_items].size
    assert_equal expected_item.scc, return_data[:all_items].first.scc
  end

end
