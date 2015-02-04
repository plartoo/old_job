require File.dirname(__FILE__) + '/test_helper'

class BrandTest < Test::Unit::TestCase

  def setup
    @brands = [
      {"name" => "brand a", "id" => 1},
      {"name" => "brand b", "id" => 2}
    ]
    Brand.send(:class_variable_set, "@@brands", {})
  end

  ### Turned off because we have to fix the brand file in SITM side to make this test pass
  ### related pivotal story <https://www.pivotaltracker.com/story/show/8264999>
#  def test_brand_matching_should_match_all_existing_brands
#    %w(womens mens girls boys womens_run_clothes womens_run_shoes mens_run_clothes mens_run_shoes).each do |d|
#      brands = YAML.load_file(File.dirname(__FILE__) + "/../config/common/brands/#{d}_brands.yml")
#      brands.each do |b|
#        assert_equal b["id"], Brand.get_best_matching_brand_bm(d.to_sym, b["name"]), "Brand #{b['name']} for department #{d} was not found by Brand.get_best_matching_brand_bm"
#      end
#    end
#  end
  
  def test_should_load_additional_brand_mappings
    Brand.expects(:load_additional_brand_mappings).with(:womens)
    Brand.load_brand_mapper(:womens)
  end
  
  def test_load_additional_brand_mappings_adds_brands_to_mapper
    Brand.stubs(:brands_from_yml_file).returns(@brands)
    Brand.expects(:add_brands_to_mapper).with(:womens, @brands)
    Brand.load_additional_brand_mappings(:womens)
  end

  def test_load_brand_mapper_adds_brands_to_mapper
    Brand.stubs(:brands_from_yml_file).returns(@brands).returns([])
    Brand.expects(:add_brands_to_mapper).with(:womens, @brands)
    Brand.expects(:add_brands_to_mapper).with(:womens, [])
    Brand.load_brand_mapper(:womens)
  end

  def test_add_brands_to_mapper_adds_brands_to_mapper
    brand_mappers = {}
    brand_mappers[:womens] = BrandMapper.new
    Brand.send(:class_variable_set, "@@brands", brand_mappers)
    Brand.send(:class_variable_get, "@@brands")[:womens].expects(:add_brand).with("brand a",1)
    Brand.send(:class_variable_get, "@@brands")[:womens].expects(:add_brand).with("brand b",2)
    Brand.add_brands_to_mapper(:womens, @brands)
  end
  

end
