$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')

require 'fetcher'

class WhiteHouseBlackMarket

  extend Fetcher
  include FetcherInstance

  MAIN_URL = 'http://www.whitehouseblackmarket.com'
  start_url = 'http://www.whitehouseblackmarket.com/store/search/search_results.jsp?_DARGS=/store/include/header.jsp.2_AF&_dynSessConf=-1281015941534105350&trail=10275%3Acat4809277&_D%3Aqfh_ft=+&qfh_fsr=true&_D%3Aqfh_fsr=+&qfh_cl=true&_D%3Aqfh_cl=+&catId=cat4809277&fsrp_sf=true&_D%3Afsrp_sf=+&qfh_ft=10275%3Acat4809277&_D%3Aqfh_s_s=+&qfh_s_s=submit'
  categories :main_url => MAIN_URL, :start_url => start_url, :department => :womens do
    is 'a'
    ancestor :selector => 'ul#shopSaleCategory_child'
  end

  items :main_url => MAIN_URL, :brand => 'White House Black Market' do
    item_block do
      is "div"
      with :class => /product-capsule.*/
      ancestor do
        is "div"
        with :id => "shelfProducts"
      end
    end

   vendor_key /productId=(\d+)/

    description do
      is "a"
      with :class => "product-name"
    end

    product_url do
      is "a"
    end

    product_image  do
      is "img"
      with :class => "product-image"
    end

    original_price_custom do |item_div|
      price_div = item_div.search('strike.product-price-was')
      if price_div.empty?
        price_div = item_div.search('span.product-price')
      end
      price_div.text.match(%r#\$([\d\,\.]+)#)[1] rescue nil
    end

    sale_price do
      is 'span'
      with :class => 'product-price-now'
    end

    post_process do |item,cat|
      # need to cut off product_url coz they are too long
      id = item.product_url.match(%r#productId=(\d+)#)[1] rescue nil
      if id
        item.product_url = "http://www.whitehouseblackmarket.com/store/browse/product.jsp?productId=#{id}"
      end
      item
    end

  end

  sccs SCCCustomScraper do
    give_me do
      is "script"
    end

    all_at_once

# {"sizes":[{"colorCode":"001", "colorName":"Black", "sku":"sku5059450", "size":"XS"},{"colorCode":"001", "colorName":"Black", "sku":"sku5059457", "size":"M"},{"colorCode":"001", "colorName":"Black", "sku":"sku5059473", "size":"L"},{"colorCode":"001", "colorName":"Black", "sku":"sku5059458", "size":"XL"}],"maxCount": "4"};
    process do |script|
      sccs = []
      if script.content =~ /var product\d+/
        content = script.content

        content.scan(/colorName\":\"((\w|\s|\/)+)\", \"sku\":\"sku\d+\", \"size\":\"((\w|\s|\d|\.|\-|\/)+)\"/).each do |c, n, s|
          if s.strip == "One Size"
            s = "ALL_SIZES"
          end
#          puts "COLOR: #{c.inspect}" + " Size: #{s.inspect}"
          sccs.push [s,c.strip]
        end
      end
      sccs
    end
  end
end
