require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../fetchers/victoriassecret/victoriassecret.rb'

module TestSizeMapper
  def match_within_womens_top(value, item)
    {'one' => '1'}[value]
  end
end

class SizeMatcherTest < Test::Unit::TestCase

  def setup
    @fetcher_class = Victoriassecret
    @item = Item.new
    @item.scc = []
    @item.product_url = 'url'
    @item.clothing_type = ClothingType[:CASUAL_SHIRT, :womens]
    @item.dept = :womens
    @item
  end

  def test_initialize_with_hash_should_respond_to_all_methods
    size_mapper = SizeMapper.new(@fetcher_class)
    size_mapper.add_mapper('one' => '1', 'two' => '2')
    Department.all.each do |dept|
      ClothingType.all.collect{|c| ClothingType[c, dept][:group]}.uniq.each do |group|
        next if group.nil?
        assert size_mapper.mappers[0].respond_to?("match_within_#{dept.to_s}_#{group.to_s}".to_sym)
      end
    end
  end

  def test_initialize_with_constant_should_respond_to_defined_methods
    size_mapper = SizeMapper.new(@fetcher_class)
    size_mapper.add_mapper(:test_size_mapper)
    assert size_mapper.mappers[0].respond_to?(:match_within_womens_top)
    assert !size_mapper.mappers[0].respond_to?(:match_within_mens_top)
  end

  def test_override_method_returns_value_from_new_method
    size_mapper = SizeMapper.new(@fetcher_class)
    size_mapper.add_mapper(:test_size_mapper)
    size_mapper.override_last do
      def match_within_womens_top(value, item)
        if value.downcase.gsub(/\s/, '') == 'one'
          %w(XS)
        else
          default_match_within_womens_top(value, item)
        end
      end
    end
    assert_equal ['XS'], size_mapper.mappers[0].match_within_womens_top('one', @item)
  end

  def test_override_method_returns_default_mapping_if_none_found
    size_mapper = SizeMapper.new(@fetcher_class)
    size_mapper.add_mapper(:test_size_mapper)
    size_mapper.override_last do
      def match_within_womens_top(value, item)
        if value.downcase.gsub(/\s/, '') == 'two'
          %w(XS)
        else
          default_match_within_womens_top(value, item)
        end
      end
    end
    assert_equal '1', size_mapper.mappers[0].match_within_womens_top('one', @item)
  end

  def test_override_method_returns_default_mapping_if_none_found
    size_mapper = SizeMapper.new(@fetcher_class)
    size_mapper.add_mapper(:test_size_mapper)
    size_mapper.override_last do
      def match_within_womens_top(value, item)
        if value.downcase.gsub(/\s/, '') == 'two'
          %w(XS)
        else
          default_match_within_womens_top(value, item)
        end
      end
    end
    assert_equal '1', size_mapper.mappers[0].match_within_womens_top('one', @item)
  end

  def test_initialize_size_mapper_with_a_hash_matches_using_hash
    mapper = SizeMapper.new(@fetcher_class).add_mapper({"foo" => "bar"})
    assert_equal(["bar"], mapper.map("foo", @item))

    mapper = SizeMapper.new(@fetcher_class).add_mapper({"foo2" => ["bar", "baz"]})
    assert_equal(["bar", "baz"], mapper.map("foo2", @item))
  end

  def test_use_mapper_with_hash_should_use_mappings
    mapper = SizeMapper.new(@fetcher_class)
    mapper.add_mapper({"one" => "two"})
    mapper.add_mapper({"two" => nil})
    assert_equal ['two'], mapper.map('one', @item)
  end

  def test_use_mapper_with_hash_should_use_mappings_and_return_last_non_nil_match
    mapper = SizeMapper.new(@fetcher_class)
    mapper.add_mapper({"one" => "two"})
    mapper.add_mapper({"two" => nil})
    mapper.add_mapper({nil => 'bad_value'})
    assert_equal ['two'], mapper.map('one', @item)
  end

  def test_use_mapper_with_hash_should_use_mappings_and_return_last_match
    mapper = SizeMapper.new(@fetcher_class)
    mapper.add_mapper({"one" => "two"})
    mapper.add_mapper({"two" => "three"})
    mapper.add_mapper({"three" => "four"})
    assert_equal ['four'], mapper.map('one', @item)
  end


end

