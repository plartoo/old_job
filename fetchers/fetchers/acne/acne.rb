$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')

require 'fetcher'

class Acne

  extend Fetcher
  include FetcherInstance

  $seen_vendor_keys = {}
  DUPLICATE_MESSAGE = "duplicate item"

  MAIN_URL = 'http://shop.acnestudios.com'

  categories :ignore_categories => true

#  OUTLET_URL = 'http://shop.acnestudios.com/outlet/outlet-women.html'
#
#  categories :main_url=>MAIN_URL, :start_url=>OUTLET_URL do
#    is 'a'
#    ancestor :selector => 'div#HeaderMenu ul li'
#    ignore /new arrivals|most viewed|pop classics|main collection|pre collection|
#    wish list|shopping help|size guide/i
#  end

  items :main_url => MAIN_URL, :brand=>'Acne' do
    item_block do
      is 'div'
      with :class => /item row/
    end

    vendor_key /.*\/(.*?)\.html/

    description do
      is 'span'
      with :class => 'name'
    end

    notice_custom do |item_div|
      unique_part_of_item_desc = item_div.search('span.name').text rescue nil
      unless $seen_vendor_keys.has_key?(unique_part_of_item_desc)
        $seen_vendor_keys[unique_part_of_item_desc] = true
        nil
      else
        DUPLICATE_MESSAGE
      end
    end

    product_url do
      is 'a'
    end

    product_image do
      is 'img'
      width 194
      height 259
    end

    original_price_custom do |item_div|
      item_div.children.text.match(%r#([\d\,\.]+) (USD|GBP)#i)[1].strip.gsub(%r#\s#,'') rescue nil
    end

    sale_price_custom do |item_div|
      item_div.text.match(%r#.*SALE.*?([\d\,\.]+) (USD|GBP)#)[1].strip.gsub(%r#\s#,'') rescue nil
    end

    ### took this off and searched/replaced in category file
#    pagination do
#      view_all_append '?limit=all'
#    end

    post_process do |item,cat|
      if cat.name.match(%r#kidswear#i) && item.description.match(%r#girls?#i)
        item.dept = :girls
        item.department_bm = 2
      end
      # for items such as 'aktie trouser1' which will fail the clothing type pattern REGEX
      if item.clothing_type.nil? && item.description.match(%r#trouser#)
        item.clothing_type = {:group=>:bottom, :bm=>2}
        item.clothing_type_bm = 2
      end

      ## trie doesn't recognize brand "Acne Miniature by Acne" if the query is just "Acne (Miniature)"
      if item.brand.nil? && item.dept.to_s.match(/girls|boys/i)
        item.brand_bm = Brand.get_best_matching_brand_bm(item.dept,"Acne Miniature by Acne")
      end

      if item.notice.eql?(DUPLICATE_MESSAGE)
        item.vendor_key = nil
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
      size_mapper = SizeMapper.new(self.fetcher_class)

      if I18nVersion == "us"
        size_mapper.add_mapper :acne_us_size
        size_mapper.add_mapper :euro_shoe_to_us_shoe
      elsif I18nVersion == "uk"
        size_mapper.add_mapper :acne_uk_size
        size_mapper.add_mapper :euro_shoe_to_uk_shoe
      end
      matchers size_mapper

      ## two ways to scrape image dimension; the REGEX approach is fragile but it's faster
      img_url = page.content.match(/DOWNLOAD FLASH.*?(http.*?\.jpg)/im)[1] rescue nil
      if img_url
        item.product_image.update_image_dimension(agent.agent,img_url,{'Range' => 'bytes=0-700'})
      end

      # FINALLY....real size scraping stuff
      sccs = []
      json = page.content.match(%r#var spConfig.*?\((.*)\)\;#i)[1] rescue nil
      unless json.nil?
        json = JSON.parse(json)
        color_hash = {}
        if json['attributes'].values.size > 1
          size_arr = json['attributes'].values.first['options']
          color_arr = json['attributes'].values.last['options']
        elsif json['attributes'].values.size == 1 # only size info is available
          size_arr = json['attributes'].values.first['options']
          color_arr = []
        end

        unless color_arr.empty?
          color_arr.each do |ch|
            ch['products'].each do |product_code|
              color_hash[product_code] = ch['label']
            end
          end
        end

        unless size_arr.empty?
          sccs = []
          size_arr.each do |sh| # each 'sh' is like {"price"=>"0", "label"=>"50", "id"=>"264", "products"=>["17461"]}
            sh['products'].each do |product_code|
              unless color_hash.empty?
                sccs.push [sh['label'],color_hash[product_code]]
              else
                sccs.push [sh['label'],'Unknown']
              end
            end
          end
        else
          puts "size_arr empty\n#{item.product_url}"
        end
      else
        puts "json can't be found.\n#{item.product_url}"
      end

      sccs
    end
  end

end
