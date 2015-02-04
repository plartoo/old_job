require 'test_helper'

class SCCFromHashedJsonScraperTest < Test::Unit::TestCase

  def setup
    Victoriassecret.log = Logger.new(STDOUT)
  end

  def test_scrape
    sccs = SCCFromHashedJSONScraper.new(Victoriassecret) do
      testing
      json_variable 'detailData'

      size_hash_name 'sizeData'
      colors_in_size_name 'colors'
      
      color_hash_name 'colorData'
      color_name_in 'colorName'
    end

    item = Item.new
    item.product_url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'html', 'detail_page_for_hashed_json_scraper.html'))
    item.dept = :womens
    item.clothing_type = ClothingType[:JEANS,item.dept]
    sccs = sccs.scrape({:item => item})

    expected_sccs = [{:color=>"Ink", :size=>"24"},
                     {:color=>"Ink", :size=>"25"},
                     {:color=>"Black", :size=>"25"},
                     {:color=>"Ink", :size=>"26"},
                     {:color=>"White", :size=>"26"},
                     {:color=>"Black", :size=>"26"},
                     {:color=>"Ink", :size=>"27"},
                     {:color=>"White", :size=>"27"},
                     {:color=>"Black", :size=>"27"},
                     {:color=>"Ink", :size=>"28"},
                     {:color=>"White", :size=>"28"},
                     {:color=>"Black", :size=>"28"},
                     {:color=>"Ink", :size=>"30"},
                     {:color=>"White", :size=>"30"},
                     {:color=>"Black", :size=>"30"},
                     {:color=>"Ink", :size=>"29"},
                     {:color=>"White", :size=>"29"},
                     {:color=>"Black", :size=>"29"},
                     {:color=>"Ink", :size=>"31"},
                     {:color=>"White", :size=>"31"},
                     {:color=>"Black", :size=>"31"},
                     {:color=>"Ink", :size=>"32"},
                     {:color=>"White", :size=>"32"},
                     {:color=>"Black", :size=>"32"}]


    assert_equal(expected_sccs, sccs)
  end

end
