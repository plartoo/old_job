require File.dirname(__FILE__) + '/test_helper'

class CategoryTest < Test::Unit::TestCase

  def test_guess_dept_from_url_should_guess_dept
    cat = Category.new('test', 'http://www.urbanoutfitters.co.uk/Clothing/Skirts/icat/skirtsshorts&bklist=icat,5,shop,womens,womensclothing,skirtsshorts')
    assert_equal :womens, cat.guess_dept_from_url

    cat = Category.new('test', 'http://www.urbanoutfitters.co.uk/Shop-By-Brand/All-Son/icat/allson&bklist=icat,5,shop,mens,mensbrands,allson')
    assert_equal :mens, cat.guess_dept_from_url

    cat = Category.new('test', 'http://www.frenchconnection.com/category/kids+boys/Boys.htm')
    assert_equal :boys, cat.guess_dept_from_url

    cat = Category.new('test', 'http://www.frenchconnection.com/category/kids++girls+Jeans/Jeans.htm')
    assert_equal :girls, cat.guess_dept_from_url
  end

  def test_to_hash_should_guess_dept
    cat = Category.new('test', 'http://www.urbanoutfitters.co.uk/Clothing/Skirts/icat/skirtsshorts&bklist=icat,5,shop,womens,womensclothing,skirtsshorts', false, :SHOES, nil)
    expected = {
      :dept=>:womens,
      :name=>"test",
      :clothing_type=>:SHOES,
      :ignored=>false,
      :category_path=>[],
      :url=>"http://www.urbanoutfitters.co.uk/Clothing/Skirts/icat/skirtsshorts&bklist=icat,5,shop,womens,womensclothing,skirtsshorts"
    }
    assert_equal expected, cat.to_hash
  end

  def test_to_hash_should_not_guess_dept_when_specified
    cat = Category.new('test', 'http://www.urbanoutfitters.co.uk/Clothing/Skirts/icat/skirtsshorts&bklist=icat,5,shop,womens,womensclothing,skirtsshorts', false, :SHOES, :boys)
    expected = {
      :dept=>:boys,
      :name=>"test",
      :clothing_type=>:SHOES,
      :ignored=>false,
      :category_path=>[],
      :url=>"http://www.urbanoutfitters.co.uk/Clothing/Skirts/icat/skirtsshorts&bklist=icat,5,shop,womens,womensclothing,skirtsshorts"
    }
    assert_equal expected, cat.to_hash
  end

  def test_prioritized_category_has_prioritized_returns_true
    cat = Category.new('test', 'http://www.', false, :SHOES, :boys)
    cat.prioritized = false
    assert !cat.prioritized?
    cat.prioritized = true
    assert cat.prioritized?
  end

  def test_to_hash_should_add_brand_if_defined
    cat = Category.new('test', 'http://www.urbanoutfitters.co.uk/Clothing/Skirts/icat/skirtsshorts&bklist=icat,5,shop,womens,womensclothing,skirtsshorts', false, :SHOES, :boys)
    cat.brand = "brand"
    expected = {
      :dept=>:boys,
      :name=>"test",
      :clothing_type=>:SHOES,
      :ignored=>false,
      :category_path=>[],
      :brand => "brand",
      :url=>"http://www.urbanoutfitters.co.uk/Clothing/Skirts/icat/skirtsshorts&bklist=icat,5,shop,womens,womensclothing,skirtsshorts"
    }
    assert_equal expected, cat.to_hash
  end

end