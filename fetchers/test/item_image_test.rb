require 'test_helper'

class ItemImageTest < Test::Unit::TestCase

  def setup
    @fetcher_class = Victoriassecret
    @item_scraper = ItemScraper.new(@fetcher_class,{}) do
      vendor_key /(\d+)/
      item_block "/html/body/table/tr/td"
      testing
      description do
        is "span"
        with :name => "product"
      end
      product_url do
        is "a"
        with :href => /null\.html/
      end
      product_image do
        is "img"
        with :src => /null\.png/
        default_width 100
        default_height 100
      end
      original_price do
        is "span"
        with :id => "oprice"
      end
      sale_price do
        is "span"
        with :id => "sprice"
      end
    end    
  end

  def test_default_dimensions
    item_work_queue = FetcherWorkQueue.new
    @item_scraper.scrape({:cat => Category.new("", "/item_page_for_image_match.html", "", nil, :womens),
        :item_work_queue => item_work_queue})
    
    items = []
    while item_work_queue.size > 0
      items << item_work_queue.pop[:work]
    end
    item_imgs = items.map {|item| [item.description, item.product_image]}
    item_imgs.each do |img|
      if img[0] == "jacket with width and height"
        assert_equal 130.to_s, img[1].width.to_s
        assert_equal 140.to_s, img[1].height.to_s
      else
        assert_equal 100.to_s, img[1].width.to_s
        assert_equal 100.to_s, img[1].height.to_s
      end
    end
  end

  def test_resize_to_max_doesnt_update_when_smaller
    height = 50
    width = 25
    max_width = 100
    image = ItemImage.new("",width,height)
    image.resize_to_max(max_width)
    assert_equal height, image.height
    assert_equal width, image.width
  end

  def test_resize_to_max_scales_correctly_when_larger
    height = 50
    width = 100
    max_width = 50
    image = ItemImage.new("",width,height)
    image.resize_to_max(max_width)
    assert_equal (height/2).to_s, image.height
    assert_equal (width/2).to_s, image.width
  end

  def test_update_image_dimension_updates_image_object_when_headers_are_not_supplied
    agent = Mechanize.new
    url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'images', 'shirt_260_345.jpg'))

    image = ItemImage.new("",1234,5678)
    image.update_image_dimension(agent,url)

    assert_equal 260, image.width
    assert_equal 345, image.height
    assert_equal url, image.url
  end

  ## NOTE: for files that exists on the disk, Mechanize doesn't care about 
  # headers and just retrieves FULL size. That's why we can't test/check the 
  # correctness of output in this case and rather check to just make sure that 
  # the parameters are passed in as expected
  def test_update_image_dimension_uses_headers_when_they_are_supplied
    agent = Mechanize.new
    url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'images', 'shirt_260_345.jpg'))
    header = {'Range' => 'bytes=0-700'}
    agent.expects(:get).with({:url=>url,:headers=>header}).returns(Mechanize.new.get(url))

    image = ItemImage.new("",1234,5678)
    image.update_image_dimension(agent,url,header)
  end

  def test_resize_to_max_does_resize_when_do_not_resize_method_has_not_been_called
    agent = Mechanize.new
    url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'images', 'shirt_260_345.jpg'))

    image = ItemImage.new("",1234,5678)
    image.update_image_dimension(agent,url)

    image.resize_to_max

    assert_equal "170", image.width
    assert_equal "225", image.height
  end

  def test_resize_to_max_does_not_resize_when_do_not_resize_method_has_been_called
    agent = Mechanize.new
    url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'images', 'shirt_260_345.jpg'))

    image = ItemImage.new("",1234,5678)
    image.update_image_dimension(agent,url)

    image.do_not_resize
    image.resize_to_max

    assert_equal 260, image.width
    assert_equal 345, image.height
  end
end
