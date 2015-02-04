$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')

require 'fetcher'

class Adam

  extend Fetcher
  include FetcherInstance

  MAIN_URL = ' http://www.shopadam.com/'
  ## Options for categories
  ##   :main_url - the domain of the site, e.g. 'http://www.katespade.com'
  ##   :start_url - the page to begin the category scrape on if not the main page (optional)
  ##   :ignore_categories - true if the fetcher will not dynamically check categories at fetch-time
  ##   :department - specify a department for the block (:womens, :mens, etc...) (optional)

  {
    "http://www.shopadam.com/women/icat/women/" => [:womens,"li.navwomencategory ul.lvl4"],
    "http://www.shopadam.com/men/icat/men/" => [:mens,"li.navmencategory ul.lvl4"]
  }.each do |url,data|
    categories :main_url => MAIN_URL, :department => data.first, :start_url => url do
      is 'a'
      ancestor :selector => data.last
    end
  end

  ## Options for items
  ##   :main_url - the domain of the site, e.g. 'http://www.katespade.com'
  ##   :brand - the brand of the site if the site only has a single brand
  ##   :from_detail_page - true if some item details need to be parsed off of the item detail page
  items :main_url => MAIN_URL, :brand => "ADAM" do
    ## Define the html unit that contains a single item
    ## Can be passed an explict selector, like...
    ##   item_block :selector => '/html/body/table/tr/td'
    ## or a block that defines a condition set, like...

    item_block do
      is 'li'
      ancestor :selector => 'ul.products'
    end

#    item_block

    ## Define a regular expression to get a product's unique
    ## vendor key from the product's url as the first group of the expression

    vendor_key /\/(\w+)\/?$/

    ## Required item attributes:
    ##   description
    ##   product_url
    ##   product_image
    ##   original_price
    ##   sale_price
    ##
    ## Optional item attributes:
    ##   brand
    ##   notice

    description do
      is 'h2'
      with :class => 'prodname'
    end

    product_url do
      is 'a'
    end

    ## Dimensions must be defined for an image
    ##   (width|height) - each define an explicit dimension
    ##   default_(width/height) - defines a width and height in case the html does not specify
    ## You can optionally specify a scaling factor
    ##   scale_to_(width|height) - scales the dimensions to meet a specific dimension
    ##   scale - takes a string of the form /\d+%/ and scales the image to be \d+ percent of the original
    product_image do
      is 'img'
      height 240
      width 180
    end

    ###FRIENDLY NOTE: if you're using orig/sale_price_custom, please make sure
    ### to scrape prices using Utils.get_price_str(price_text)
    original_price_custom do |div|
      if div.search('span#attr-wasprice').text.strip.empty?
        original_price = Utils.get_price_str(div.search('p.price').text)
      else
        original_price = Utils.get_price_str(div.search('span#attr-wasprice').text)
      end
    end

    sale_price_custom do |div|
      if div.search('span#attr-wasprice').any? && div.search('span#attr-wasprice').text != ""
        Utils.get_price_str(div.search('p.price').text)
      else
        nil
      end
    end

    ## If the page requires pagination, define a paginator
    pagination do
      view_all_append "&itemsperpage=1000"
    end

    post_process do |item,cat|
      if item.description =~ /peacoat|overcoat|vest/
        item.clothing_type_bm = 16
        item.clothing_type = {:group => :top, :bm => 16}
      end

      if item.description.match(/\xE9/)
        item.description = item.description.gsub(/\xE9/,"e") rescue item.description
      end

      item
    end
  end

  sccs SCCCustomScraper do
    give_me do
      is "html"
    end

    all_at_once

    process do |page|
      sccs = []
      color_sizes = page.text.scan(/product\.setAttributeData\(.*?att1\: '(.*?)',.*?att2\: '(.*?)'/m)
      sccs = color_sizes.map{|color,size| [size,color]}
      sccs
    end
  end

end
