require 'test_helper'

class CategoryGeneratorTest < Test::Unit::TestCase

  def setup
    ClothingTypeMatcher.i18n_version = 'us'
    @fetcher = Victoriassecret.new
    @cats = CategoryScraper.new(Victoriassecret,{:department=>:womens}) do
      testing
      start_url "/category_page.html"
      with_id "imacategory"
      ignore /category\s1/
    end
  end

  def test_yaml
    cats = @cats.scrape
    gen = CategoryGenerator.new cats, @fetcher
    cats = CategoryGenerator.load_yaml(gen.to_yaml)

    assert_equal 1, cats[:ignored].size
    assert_equal 1, cats[:active].size
    assert_equal "category 1", cats[:ignored][0].name
    assert_equal "category 2", cats[:active][0].name
  end
  
  def test_diff_new
    cats = @cats.scrape
    gen = CategoryGenerator.new cats, @fetcher
    cats = CategoryGenerator.load_yaml(gen.to_yaml)
    
    new = [cats[:active][0], Category.new("name", "url")]

    diff = CategoryGenerator.generate_diff(cats[:active], new)
    
    assert_equal 1, diff[0].size
    assert_equal 0, diff[1].size
    assert_equal "name", diff[0][0].name
  end

  def test_diff_missing
    cats = @cats.scrape
    gen = CategoryGenerator.new cats, @fetcher
    cats = CategoryGenerator.load_yaml(gen.to_yaml)

    new = []

    diff = CategoryGenerator.generate_diff(cats[:active], new)

    assert_equal 0, diff[0].size
    assert_equal 1, diff[1].size
    assert_equal "category 2", diff[1][0].name
  end

end
