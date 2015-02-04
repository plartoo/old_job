$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')

require 'fetcher'

class AlexanderWang

  extend Fetcher
  include FetcherInstance

  MAIN_URL = 'http://www.alexanderwang.com'

#  START_URL = 'http://www.alexanderwang.com/shop'
#
#  categories :main_url => MAIN_URL, :start_url => START_URL do
#    is 'a'
#    ancestor :selector => 'ul.category-set li'
#  end

  items :main_url => MAIN_URL, :brand => 'Alexander Wang' do
    item_block :selector => 'li.cell.product'

    vendor_key /.*\/(.*?\/.*)/

    description do
      is 'a'
      with :class => 'product-name'
    end

    product_url do
      is 'a'
    end

    product_image do
      is 'img'
    end

    original_price_custom do |item_div|
      price_div = item_div.search('li.product-price-retail')
      
      if price_div.empty?
        price_div = item_div.search('li.product-price')
      end

      Utils.get_price_str(price_div.text) rescue nil

    end

    sale_price_custom do |item_div|
      Utils.get_price_str(item_div.search('li.product-price-markdown').text) rescue nil
    end

    ## If the page requires pagination, define a paginator
    pagination do
      view_all_append '?p=0'
    end

#    post_process do |item,cat|
#      pp item
#      item
#    end
  end

  sccs SCCCustomScraper do
    give_me do
      is "html"
    end

    all_at_once

    process do |page|
      sccs = []
      color_urls = page.search('div#product_options div div.clear ul.option-value-set li.link a')

      color_urls.each do |color_html|
        url = MAIN_URL + color_html.attr('href')
        color = color_html.attr('title') rescue 'Unknown'
        page = agent.agent.get(url)
        page.search('select#skuid option').each do |sd|
          size = sd.text
          sccs.push [size, color]
        end
      end

      sccs
    end

    extended_description_data do |page|
      desc = {}
      meta = page.search('meta')
      desc[:full_description] = page.search("div.product-copy.preview-text").to_s
      desc[:meta_description] = meta.select{|x| x.attr('name') =~ /description/i}.first.attr('content') rescue ""
      desc[:meta_keywords] = meta.select{|x| x.attr('name') =~ /keywords/i}.first.attr('content') rescue ""
      desc
    end

    additional_images do |page|
      images = {:primary => nil, :all => []}
      images[:primary] = page.search("div.product-visual div.variant-image img.variant-image-img").first.attr('src') rescue nil
      
      page.search('ul.alternate-visuals-set li img.alternate-visual-img').each do |img_div|
        images[:all] << img_div.attr('src')
      end

      images[:all].unshift images[:primary]

      images
    end

    related_vendor_keys do |page|
      vendor_keys = []
      similar_item_divs = page.search('li.crosssell-thumbnail a')

      similar_item_divs.each do |div|
        key = div.attr('href').match(/.*\/(.*?\/.*)/)[1] rescue nil
        vendor_keys << key if key
      end

      vendor_keys
    end

  end

end
