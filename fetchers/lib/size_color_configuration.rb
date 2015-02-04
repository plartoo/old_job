class SizeColorConfiguration # :nodoc:
  attr_accessor :size, :color

  def initialize(size, color)
    @size = size
    @color = color
  end

  def to_h
    return unless valid?
    
    {:size_bm => @size[:bm],
      :size_type_bm => @size[:type_bm],
      :color => @color
    }
  end

  def to_s
    [@size, @color].to_s
  end

  def valid?
    !@size[:bm].nil? && !@size[:type_bm].nil? && !@color.nil?
  end

  def ==(obj)
    unless obj.is_a? SizeColorConfiguration
      raise "cannot compare SizeColorConfiguration to #{obj.class}"
    end

    obj.size[:bm] == @size[:bm] &&
      obj.size[:type_bm] == @size[:type_bm] &&
      obj.color == @color
  end
  def hash
    31*(@size[:bm] + 31*@size[:type_bm]) + @color.hash
  end
  alias_method :eql?,:==
end
