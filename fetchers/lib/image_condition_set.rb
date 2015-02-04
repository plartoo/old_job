require 'condition_set'

class ImageConditionSet < ConditionSet
  attr_accessor :default_dimensions, :buffer_width

  def initialize(from_detail_page=false, &definition)
    @conditions = []
    @from_detail_page = from_detail_page
    self.instance_eval(&definition)
    raise "no element type specified" if @element.nil?
    @buffer_width ||= 125
  end

  def width(width)
    @width = width
  end

  def height(height)
    @height = height
  end

  def default_width(width)
    @default_width = width
  end

  def default_height(height)
    @default_height = height
  end

  def default_buffer_width(width)
    @buffer_width = width
  end

  def scale_to_width(width)
    @desired_width = width
  end

  def scale_to_height(height)
    @desired_height = height
  end

  def scale(percent)
    if percent.is_a?(Float)
      @scale = percent
    elsif percent.is_a?(String)
      @scale = percent.match(/(\d+)%/)[1].to_f / 100.0
    end
  end

  def get_image(node)
    image = ItemImage.new(node[:src])
    image.buffer_width = @buffer_width

    if @width and @height
      image.width = @width
      image.height = @height
    else
      image.width = node[:width].nil? ? @default_width : node[:width]
      image.height = node[:height].nil? ? @default_height : node[:height]
    end

    if @desired_width
      image.height = (image.height.to_f * @desired_width.to_f / image.width.to_f).to_i.to_s
      image.width = @desired_width
    elsif @desired_height
      image.width = (image.width.to_f * @desired_height.to_f / image.height.to_f).to_i.to_s
      image.height = @desired_height
    elsif @scale
      image.width = (image.width.to_f * @scale).to_i.to_s
      image.height = (image.height.to_f * @scale).to_i.to_s
    end
    
    image
  end

end
