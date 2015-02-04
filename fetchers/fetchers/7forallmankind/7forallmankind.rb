$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'fetcher'

class SevenForAllMankind

  extend Fetcher
  include FetcherInstance

  MAIN_URL = 'http://www.7forallmankind.com'
#  URLS = [
#    'http://www.7forallmankind.com/Sale_Women_View_All/pl/c/254601.html',
#    'http://www.7forallmankind.com/Sale_Men_View_All/pl/c/254602.html',
#  ]
#  DEPTS = [:womens, :mens]
#  URLS.each_with_index do |url,i|
#    categories :main_url => MAIN_URL , :start_url=>url do
#      is "a"
#      ancestor :selector => 'li.active ul.sub li'
#    end
#  end

  FULL_PRICE = [
    {:url => "http://www.7forallmankind.com/women.html", :dept => :womens, :category_path => "woman", :ancestor => "li.active ul li"},
    {:url => "http://www.7forallmankind.com/men.html", :dept => :mens, :category_path => "man", :ancestor => "li.active ul li"},
    {:url => "http://www.7forallmankind.com/footwear.html", :dept => :womens, :category_path => "Footwear", :ancestor => "li.active ul li"},

    {:url => "http://www.7forallmankind.com/Sale_Women_View_All/pl/c/254601.html", :dept => :womens, :category_path => "woman", :ancestor => "ul.sub li"},
    {:url => "http://www.7forallmankind.com/Sale_Men_View_All/pl/c/254602.html", :dept => :mens, :category_path => "man", :ancestor => "ul.sub li"},
    {:url => "http://www.7forallmankind.com/Sale_Footwear/pl/c/328.html", :dept => :womens, :category_path => "Footwear", :ancestor => "ul.sub li"},
  ].each do |data|
    categories :main_url=>MAIN_URL, :start_url=>data[:url], :department=>data[:dept], :category_path => data[:category_path] do
      is 'a'
      ancestor :selector => data[:ancestor]
      ignore /View all|new arrivals|online exclusives|shop by/i
    end
  end

  items :main_url => MAIN_URL, :brand => '7 For All Mankind' do
    item_block do
      is 'li'
      ancestor :selector => 'ul.products'
    end

    vendor_key /(\d+).html/

    description_custom do |item_div|
      item_div.search('span.name').children.first.text
    end

    product_url do
      is 'a'
    end

    product_image do
      is 'img'
      width 172
      height 258
    end

    original_price_custom do |item_block|
      price_div = item_block.search('span.name strike')
      if price_div.empty?
        price_div = item_block.search('span.name')
      end
      price_div.text.match(%r#\$([\d\,\.]+)#)[1] rescue nil
    end

    sale_price_custom do |item_block|
      price_div = item_block.search('span.name strike')
      if !price_div.empty?
        sale_price = item_block.search('span.name').text.match(%r#now.*?\$([\d\,\.]+)#i)[1] rescue nil
      end
      sale_price
    end

    ## If the page requires pagination, define a paginator
    pagination do
      preprocess do |url|
        category_id_regexp = %r(.*/(.*)\.html)
        if category_id_regexp
          cat_id = url[category_id_regexp,1]
          "http://www.7forallmankind.com/store/productslist.aspx?categoryid=#{cat_id}&PageNo=0"
        else
          url
        end
      end
    end

    post_process do |item,cat|
      # they lump kids item into one category, which is currently defaulted to :boys
      if item.description.match(/\bgirls?/i)
        item.dept = :girls
      end

      if cat.name.match(%r#boys|girls#i) && item.description.match(%r#relaxed|bootcut|straight leg|flare|bell bottom|denim#i)
        item.clothing_type = {:group=>:bottom , :bm=>6}
      end

      # remove maternity items because they're only a fraction of their inventory and it'll screw up the simple sccs scraping part
      if item.description.match(/maternity/i)
        item.vendor_key = nil
      end

      item
    end
  end

  #addProduct("2524", new Prd("2524","XS","Regular","Black","Black","0"),"true")
  sccs SCCCustomScraper do
    give_me do
      is "html"
    end

    all_at_once

    process do |page|
      size_mapper = SizeMapper.new(self.fetcher_class)
      if I18nVersion == "us"
        size_mapper.add_mapper :seven_for_all_mankind_us_size
      end
      matchers size_mapper

      script = page.search('script').select{|x| x.text.match(/addProduct/)}.first.text rescue ''
      script.scan(/Prd\(".+?","(.+?)",".+?","(.+?)".*?"1"/)
    end

    extended_description_data do |page|
      desc = {}
      meta = page.search('meta')
      desc[:full_description] = page.search('div.product-details div p:nth-child(5)').to_s
      desc[:meta_description] = meta.select{|x| x.attr('name') == 'description'}.first.attr('content') rescue ""
      desc[:meta_keywords] = meta.select{|x| x.attr('name') == 'keywords'}.first.attr('content') rescue ""

      desc
    end

    additional_images do |page|
      images = {:primary => nil, :all => []}
      url_stem = MAIN_URL + '/store/productimages/regular/'
      img_ids = page.search('div.prod-thumbnails ul li a').map{|x| x.children.first.attr('src').match(/.*\/(.*?jpg)$/)[1]}
      ### NOTE: can't do scraping for other images since javascript is not turned on
      images[:all] = img_ids.map{|x| url_stem + x.gsub(/_t.jpg/,'.jpg')}
      images[:primary] = images[:all].first

      images
    end

    related_vendor_keys do |page|
      items = []
      v_key = /productid=(\d+)/i
      items = page.search('div.also-bought-item a').map{|x| x.attr('href').match(v_key)[1] rescue nil}.compact

      items.uniq
    end

  end



end
