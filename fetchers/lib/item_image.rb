class ItemImage # :nodoc:
  attr_accessor :url, :width, :height, :buffer_width

  class << self
    attr_accessor :width
  end

  self.width = 170.0

  def initialize(url, width=nil, height=nil, buffer_width=nil)
    @url = url
    @width = width
    @height = height
    @buffer_width = buffer_width
    @resize = true
  end

  def valid?
    !(@width.nil? || @height.nil? || @url.nil? || @buffer_width.nil?)
  end

  def do_not_resize
    @resize = false
  end

  def resize_to_max(max_width = ItemImage.width)
    return if !@resize
    return if @width.to_f < max_width

    @height = (max_width*(@height.to_f/@width.to_f)).to_i.to_s
    @width = max_width.to_i.to_s
  end

  def to_hash
    { :url => @url,
      :width => @width,
      :height => @height,
      :buffer_width => @buffer_width
    }
  end

  ## use this to scrape images from detail pages
  def update_image_dimension(agent, img_url, optional_headers={})
    img_page = agent.get(:url=>img_url, :headers => optional_headers)
    img_file = JPEG.new(StringIO.new(img_page.body))
    @url = img_url
    @width = img_file.width
    @height = img_file.height
  end
end
