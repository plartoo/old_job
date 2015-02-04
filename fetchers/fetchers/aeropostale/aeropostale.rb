$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')

require 'fetcher'

class Aeropostale

  extend Fetcher
  include FetcherInstance

  MAIN_URL = 'http://www.aeropostale.com'

  URLS = [
    'http://www.aeropostale.com/category/index.jsp?categoryId=3534623', # womens
    'http://www.aeropostale.com/category/index.jsp?categoryId=3534624', # guys
    'http://www.aeropostale.com/category/index.jsp?categoryId=3534626', # sale
    'http://www.aeropostale.com/category/index.jsp?categoryId=3534630', # girls
    'http://www.aeropostale.com/category/index.jsp?categoryId=3534631', # boys
    'http://www.aeropostale.com/category/index.jsp?categoryId=3534633' # kids clearance
  ]

  DEPTS = [:womens,:mens,:womens,:girls,:boys,:girls]

  URLS.each_with_index do |url,i|
    categories :main_url => MAIN_URL, :start_url => url, :department=>DEPTS[i] do
      is 'a'
      ancestor :selector => 'div.middle'
    end
  end

  items :main_url => MAIN_URL, :brand => "A\xC3\xA9ropostale" do

    item_block do
      is 'div'
      with :class => /item/
    end

    vendor_key /productId=(\d+)/

    description do
      is 'a'
      ancestor :selector => 'h4'
    end

    product_url do
      is 'a'
    end

    product_image do
      is 'img'
      with :id => /prodShot/
      width 182
      height 212
    end

    original_price do
      is 'li'
      ancestor :selector => 'ul.price'
    end

    sale_price do
      is 'li'
      with :class => 'now'
    end

    pagination do
      view_all_append '&view=all'
    end

    post_process do |item,cat|
      if cat.name.match(%r#athletic#i)
        if item.clothing_type[:group] == 'top'
          item.clothing_type = {:group => 'top', :bm => '21'}
        elsif item.clothing_type[:group] == 'bottom'
          item.clothing_type = {:group => 'bottom', :bm => '20'}
        end
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
      size_mapper.add_mapper  'XS/S' => ['XS','S'], 'S/M' => ['S','M'],
        'M/L' => ['M','L'], 'L/XL' => ['L','XL'],

        'XSMALL' => 'XS', 'SMALL' => 'S', 'MEDIUM' => 'M',
        'LARGE' => 'L', 'XLARGE' => 'XL', 'XXLARGE'=> 'XXL',

        '3XL' => 'XXXL'

      if I18nVersion == "us"
        size_mapper.add_mapper :aeropostale_us_size
      end
      matchers size_mapper

      sccs = []
      pid = item.product_url.match(%r#productId=(\d+)#)[1] rescue ''
      sc_pairs = page.content.scan(%r#itemMap\[\d+\] = (\{[^\}]+\};)#m) rescue []
      unless sc_pairs.empty?
        sc_pairs = sc_pairs.flatten.select{|x| x.match(%r<#{pid}>)}
        sc_pairs.each do |scp|
          if scp.match(%r#IN_STOCK#)
            size = scp.match(%r#sDesc: "(.*?)"#)[1] rescue 'N/A'
            color = scp.match(%r#cDesc: "(.*?)"#)[1] rescue 'Unknown'
            sccs.push [size,color]
          end
        end
      end
      sccs
    end
  end

end
