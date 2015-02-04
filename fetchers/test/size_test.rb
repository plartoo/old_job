require File.dirname(__FILE__) + '/test_helper'
require 'sqlite3'

class SizeTest < Test::Unit::TestCase

  def setup
    @item = Item.new
    @item.dept = :womens
    @item.clothing_type = ClothingType[:DRESS,@item.dept]
  end

  def test_womens_sizes
    size = Size.get_size(Victoriassecret,"2", @item)[0]
    assert_equal(11, size[:bm])

    size = Size.get_size(Victoriassecret,"PETITE", @item)[0]
    assert_equal(7, size[:bm])

    @item.clothing_type = ClothingType[:CASUAL_PANTS,:womens]
    size = Size.get_size(Victoriassecret,"0", @item)[0]
    assert_equal(10, size[:bm])
  end

  def test_size_types    
    size = Size.get_size(Victoriassecret,"2", @item)[0]
    assert_equal(2, size[:type_bm])

    @item.dept = :mens
    @item.clothing_type = ClothingType[:BAG,@item.dept]
    size = Size.get_size(Victoriassecret,"M", @item)[0]
    assert_equal(7, size[:type_bm])

    @item.dept = :boys
    @item.clothing_type = ClothingType[:JEANS,@item.dept]
    size = Size.get_size(Victoriassecret,"16", @item)[0]
    assert_equal(9, size[:type_bm])
  end

  def test_extra_size_mappings
    @item.clothing_type = ClothingType[:JEANS,:boys]
    size = Size.get_size(Victoriassecret,"PLUS", @item)[0]
    assert_equal(6, size[:bm])

    @item.dept = :boys
    size = Size.get_size(Victoriassecret,"2", @item)[0]
    assert_equal(12, size[:bm])
  end

  def test_sizes_that_map_to_multiple_sizes
    @item.clothing_type = ClothingType[:CASUAL_SHIRT,:womens]
    sizes = Size.get_size(Victoriassecret,'XS/S', @item)
    assert_equal([{:bm=>0, :type_bm=>0}, {:bm=>1, :type_bm=>0}], sizes)
  end

  def test_empty_size
    @item.clothing_type = ClothingType[:BAG,:womens]
    size = Size.get_size(Victoriassecret,"", @item)[0]
    assert_equal(7, size[:bm])

    @item.clothing_type = ClothingType[:JEWELRY,:womens]
    size = Size.get_size(Victoriassecret,"no size", @item)[0]
    assert_equal(7, size[:bm])
  end

  def test_should_map_sizes_to_default
    size = Size.get_size(Victoriassecret,"S", @item)[0]
    size_to_default = Size.get_size(Victoriassecret,"Small", @item)[0]
    assert_equal size, size_to_default
  end

  def test_should_log_error_if_size_is_invalid
    Victoriassecret.log.expects(:error)
    assert_raises Size::InvalidSizeException do
      Size.get_size(Victoriassecret,"INVALID", @item)
    end
  end

  def test_should_validate_against_regression_suite
    regression = []
    db = SQLite3::Database.new(File.dirname(__FILE__) + "/fixtures/size_mapping_regression.db")
    db.execute("select * from regressions") do |r|
      if r[4] == "result"
        regression << {:input => [r[0], {:group => r[1].nil? ? nil : r[1].to_sym, :bm => r[2].to_i}, r[3].to_sym], :output => {:bm => r[5].to_i, :type_bm => r[6].to_i}}
      else
        regression << {:input => [r[0], {:group => r[1].nil? ? nil : r[1].to_sym, :bm => r[2].to_i}, r[3].to_sym], :output => :exception}
      end
    end
    regression.reverse! if rand(2) == 0
    regression.each do |t|
      if t[:output] == :exception
        assert_raises Size::InvalidSizeException, "InvalidSizeException expected from #{t[:input].inspect}" do
          Size.get_size(Victoriassecret,*t[:input])
        end
      else
        x = nil
        begin
          x = Size.get_size(Victoriassecret,*t[:input])
        rescue Size::InvalidSizeException
          assert false, "Unexpected exception from #{t[:input].inspect}"
        end
        assert_equal t[:output], x, "Expected #{t[:output].inspect} but was #{x.inspect} from input #{t[:input].inspect}"
      end
    end
  rescue SQLite3::SQLException
    #Ignore DB file is not checked in
  end

end
