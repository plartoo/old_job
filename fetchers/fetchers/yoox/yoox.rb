$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')

require 'fetcher'
require File.dirname(__FILE__) + '/yoox_uk_size'
require File.dirname(__FILE__) + '/yoox_us_size'

# Note: this will be the biggest category fetcher because things are broken up
# into autum-winter, spring-fall and ssale (ssale is only for mens and womens
# and it's NOT available in UK, at least up until December 7,2009)

class Yoox

  extend Fetcher
  include FetcherInstance

  MAIN_URL = 'http://www.yoox.com'

  setup do |agent|
    if I18nVersion == "uk"
      puts "Fetching UK"
      page = agent.get("http://www1.yoox.com/chooseYourCountry.asp")
      page = agent.get("http://www.yoox.com/tskay/B84CE7A2/isoCode/GB")
    elsif I18nVersion == "us"
      puts "Fetching US"
      page = agent.get("http://www1.yoox.com/chooseYourCountry.asp")
      page = agent.get("http://www.yoox.com/tskay/3FD17CD7/isoCode/US")

    end
  end

#  SALE_URLS = {
#    'http://www.yoox.com/women%27s-sale/fall-winter/department/gender/D/tskay/3FD17CD7/toll/A/dept/salewomen' => :womens,
#    'http://www.yoox.com/men%27s-sale/fall-winter/department/gender/U/tskay/3FD17CD7/toll/A/dept/salemen' => :mens,
#  }
#  SALE_URLS.each do |url, dept|
#    categories :main_url => MAIN_URL, :start_url => url, :department => dept do
#      is 'a'
#      ancestor :selector => "ul#listOfCats li[class=' macro']"
#      ignore /combined|pets|gift|tech|home|lighting|photo|planners|kitchen|textile/i
#    end
#  end

  items :main_url => MAIN_URL do
    item_block do
      is 'div'
      with :id => /item_\d+/
    end

    vendor_key /\/cod10\/(.*?)\//

    description_custom do |item_div|
      item_div.search('div.micro').text.strip rescue nil
    end

    brand do
      is 'div'
      with :class => 'brand'
    end

    product_url do
      is 'a'
    end

    product_image do
      is 'img'
      width 180
      height 233
    end

    original_price_custom do |item_div|
      price_div = item_div.search('span.oldprice')
      if price_div.empty?
        price_div = item_div.search('span.price')
      end
      Utils.get_price_str(price_div.text) rescue nil
    end

    sale_price do
      is 'span'
      with :class => 'newprice'
    end

    pagination do
      preprocess do |url|
        url + '/pg/1'
      end

      url_pattern /(pg\/)\d+/
      increment_step 1
      increment_start 1
      max_page_limit 10
    end

    post_process do |item,cat|
      if item.description.match(%r#Bermuda shorts#i) && item.dept.eql?(:mens)
        item.clothing_type = {:group=>:bottom,:bm=>24}
      end

      # brand "seventy" is mapped to "7 for all mankind" incorrectly
      if item.description.match(/^Seventy /i)
        item.vendor_key = nil
      end

      if I18nVersion == "us" && item.product_url !~ /3FD17CD7/
        ### For us dollars, tskay param must (MUST) equal '3FD17CD7'
        ### Have issues with things going to euros if tskay is some other value

        ## two formats:
        ## /tskay/some_code/
        ## &tskay=some_code&
        if item.product_url =~ /\/tskay\//
          item.product_url = item.product_url.gsub(/\/tskay\/.*?\//,"/tskay/3FD17CD7/")
        elsif item.product_url =~ /tskay=.*?&?/
          item.product_url = item.product_url.gsub(/tskay=.*?&?/,"tskay=3FD17CD7&")
        end
      end
      item
    end

  end

  sccs SCCCustomScraper do
    give_me do
      is 'html'
    end

    all_at_once

    process do |page|
      ## handle image dimensions
      unless item.product_image.nil?
        img_url = page.search('img#mainImage').attr('src').value rescue ''
        if img_url.any?
          item.product_image.update_image_dimension(agent.agent, img_url)
        end
      end

      sccs = []
      content = page.content
      json = content.match(/json.*?(\{.*\})/)[1] rescue nil
      unless json.nil?
        json = JSON.parse(json) rescue {}
        json['colors'] ||= []
        json['colors'].each do |sc|
          color_code = sc['color']
          color = page.search("div[id='parent_#{color_code}'] div").attr('title').value rescue 'Unknown'

          size = nil
          sc['sizes'].each do |size_hash|
            size = size_hash['defaultSize'] rescue nil
            if size.match(/\(.*? Size\)/)
              size = size.gsub(/\(.*? Size\)/,'').strip
            end
            sccs.push [size, color] if size
          end
        end
      else
        sccs = [['Unavailable','Unknown']]
      end

      begin
        size_mapper = SizeMapper.new(self.fetcher_class)
        size_mapper.add_mapper '--'=>'ALL_SIZES','ONESIZE'=>['XS','S','M','L']
        if I18nVersion == "us"
          size_mapper.add_mapper :yoox_us_size
        elsif I18nVersion == "uk"
          size_mapper.add_mapper :yoox_uk_size
        end
        matchers size_mapper
        sccs
      rescue Exception => e
        e
      end

    end

    extended_description_data do |page|
      desc = {}
      meta = page.search('meta')
      desc[:full_description] = page.search('div#tab1').to_s
      desc[:meta_description] = meta.select{|x| x.attr('name') == 'description'}.first.attr('content') rescue ""
      desc[:meta_keywords] = meta.select{|x| x.attr('name') == 'keywords'}.first.attr('content') rescue ""
      desc
    end

    additional_images do |page|
      images = {:primary => nil, :all => []}
      images[:primary] = page.search('img#mainImage').first.attr('src') rescue ""
      images[:all] = page.search('div#innerThumbs img').map{|x| 
        x.attr('src').gsub("_8_","_12_") rescue nil
      }.compact
      images
    end

    related_vendor_keys do |page|
      vendor_keys = []
        ## Currently these are ajax'ed out to another server:
        ## http://widget.sv.us.criteo.com/pyz/display.js?p1=v%3D2%26wi%3D7711492%26i%3D41185895&w1=getSimilarItems&p2=v%3D2%26wi%3D7709436%26pt1%3D2%26i%3D41185895&t2=sendEvent
      vendor_keys
    end
    
  end
end
