require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../fetchers/victoriassecret/victoriassecret.rb'

class SizeMatcherTest < Test::Unit::TestCase

  def setup
    @fetcher_class = Victoriassecret

    @item = Item.new
    @item.product_url = 'url'
    @item.dept = :womens
    @item.clothing_type = ClothingType[:CASUAL_SHIRT,@item.dept]
    @item
  end

  def test_matcher_should_call_map_on_mapper
    matcher = SizeMatcher.new(SizeMapper.new(@fetcher_class).add_mapper({'one' => 'two'}))
    matcher.mapper.expects(:map)
    matcher.match('one', @item)
  end

end
