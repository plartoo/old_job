require 'test_helper'

class CategoryScraperTest < Test::Unit::TestCase

  def setup
    ClothingTypeMatcher.i18n_version = 'us'
  end

  def test_basic_scrape
    cats = CategoryScraper.new(Victoriassecret,{:department=>:mens}) do
      testing
      start_url "/category_page.html"
      with_id "notacategory"
    end
    cats = cats.scrape
    assert_equal 1, cats.size
    assert_equal "foo", cats[0].name
  end

  def test_basic_scrape_with_selector
    cats = CategoryScraper.new(Victoriassecret,{:department=>:mens,:selector => 'a#notacategory', :start_url => '/category_page.html', :testing => true})
    cats = cats.scrape
    assert_equal 1, cats.size
    assert_equal "foo", cats[0].name
  end

  def test_must_define_block_or_selector
    assert_raise CategoryScraper::NoCategoryDefinitionGiven do
      CategoryScraper.new(Victoriassecret)
    end
    assert_nothing_raised do
      CategoryScraper.new(Victoriassecret,{:selector => 'CSS3'})
    end
    assert_nothing_raised do
      CategoryScraper.new(Victoriassecret) do
        is 'a'
      end
    end
  end

  def test_must_only_define_block_or_selector
    assert_raise CategoryScraper::BlockAndSelectorBothDefined do
      CategoryScraper.new(Victoriassecret,{:selector => 'CSS3'}) do
        is 'a'
      end
    end
  end

  def test_basic_scrape_hashed_dsl
    cats = CategoryScraper.new(Victoriassecret,{:start_url => '/category_page.html',:department=>:mens}) do
      testing
      with :id => "notacategory"
    end
    cats = cats.scrape
    assert_equal(1, cats.size)
    assert_equal("foo", cats[0].name)
  end

  def test_embedded_scrape
    cats = CategoryScraper.new(Victoriassecret,{:start_url => '/category_page.html',:department=>:mens}) do
      testing
      with_id "imacategory"
      
      categories do
        with_id "imacategory"
        get_name_from "name"
      end
    end
    cats = cats.scrape
    assert_equal 2, cats.size
    assert_equal [], cats.map {|c| c.name} - ["cat_name", "category 2"]
  end

  def test_specified_embedded_scrape
    cats = CategoryScraper.new(Victoriassecret,{:start_url => '/category_page.html',:department=>:mens}) do
      testing
      with :id => 'imacategory'
      
      categories :for => /1/ do
        with :id => 'imacategory'
      end
    end

    cats = cats.scrape
    assert_equal(2, cats.size, "number of scraped categories")
    assert_equal(cats.map {|c| c.name}, ["subcategory 1", "category 2"])
  end

  def test_ignore
    cats = CategoryScraper.new(Victoriassecret,{:department=>:mens,:start_url => '/category_page.html'}) do
      testing
      with_id "imacategory"
      ignore /category\s1/
    end
    cats = cats.scrape
    assert_equal 2, cats.size
    cats.each do |cat|
      if cat.name == "category 1"
        assert_equal true, cat.ignored ? true : false
      else
        assert_equal false, cat.ignored ? true : false
      end
    end
  end

  def test_brand_sets_value
    cat = CategoryScraper.new(Victoriassecret,{}) { }
    brand = "brand"
    cat.brand_string(brand)
    assert_equal brand,cat.brand
  end
  
end
