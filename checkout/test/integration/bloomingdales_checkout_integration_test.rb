require 'rubygems'
require 'ruby-debug'

require 'test/unit'
require 'active_support'
require '../../lib/http_auth_fetcher'


class BloomingdalesCheckoutIntegrationTest

  include Test::Unit::Assertions

  CONFIG_FILE = File.join(File.dirname(__FILE__), 'config', 'integration_test_config.yml')

  # for now, just stub out the items location and load items from there
  FETCHER_FOLDER = File.join(ENV['HOME'], 'workspace', 'fetchers') # on phyo's machine
  FETCHER_YAML_FILE = File.join(FETCHER_FOLDER, 'yaml_feeds', 'us', 'bloomingdales', "#{Time.now.strftime("%y%m%d")}.yml")

  # required to load Items from hash
  $:.unshift File.join(FETCHER_FOLDER, 'lib')
  require 'item'

  ASSISTED_CHECKOUT_HOST='http://0.0.0.0:4567'
#  ASSISTED_CHECKOUT_HOST='https://checkout.staging.xxxx.com'
  attr_accessor :checkout_id, :cookies, :checkout_flow_trial_number

  def initialize
    @checkout_id = rand*10000
    @config = YAML.load_file(CONFIG_FILE)
  end

  def run
    load_items
    pick_an_item
    fetch_detail
    add_to_bag
    fetch_order_data
    purchase
  end

  ############################################################## private methods below ##############################################################
  private

  def fetch(url, parms)
    JSON.parse(HttpAuthFetcher.new.fetch(url, parms))
  end

  def apparel_item
    @item
  end

  ######### STUBS ##########
  # talk with Jeremy to figure out how to get this from SITM web app
  def affiliate_url
    apparel_item.product_url
  end

  # this is a temporary hack; talk with Jeremy to figure out how to grab items from SITM database
  def load_items
    raise "Fetcher YAML file for today couldn't be found" unless File.exists?(FETCHER_YAML_FILE)
    @items = YAML.load_file(FETCHER_YAML_FILE)
  end

  def pick_an_item
    @item = Item.load_from_hash(@items[rand(@items.size)])
  end

  # once we can extract apparel_item from SITM database, this will not be needed
  def apparel_item_vendor_feed_path
    apparel_item.vendor_name
  end
  ##########################

  def pick_a_size_color(sc_detail_hash)
    sccs = sc_detail_hash['size_colors']
    @sccs_info = sccs[rand(sccs.size)].last # returns something like this: {"size_name"=>"0", "vendor_scc_value"=>"969923", "coremetricsDepthPath"=>"Dresses", "color_name"=>"Black", "sale_price"=>"126.00"}
  end

  def fetch_detail
    result = fetch("#{ASSISTED_CHECKOUT_HOST}/fetch_detail", parms_for_fetch_detail)
    if result['response_code'] == 'out_of_stock_error' # while loop???
      pick_an_item
      result = fetch("#{ASSISTED_CHECKOUT_HOST}/fetch_detail", parms_for_fetch_detail)
    end

    assert_equal "success", result['response_code']
    pick_a_size_color(result)
  end

  def add_to_bag
    result = fetch("#{ASSISTED_CHECKOUT_HOST}/add_to_bag", parms_for_add_to_bag)

    puts "result from add_to_bag:\n#{result.inspect}"
    self.cookies = result['data']['cookies'] || {}
    assert_equal "success", result['response_code']
  end

  def fetch_order_data
    result = fetch("#{ASSISTED_CHECKOUT_HOST}/fetch_order_data", parms_for_fetch_order_data)

    puts "result from fetch_order_data:\n#{result.inspect}"
    assert_equal "success", result['response_code']

    self.cookies = result['data']['cookies'] || {}
    self.checkout_flow_trial_number = result['retailer_specific_hash']['checkout_flow_trial_number']
    validate_response(result['data'])
    assert_not_nil checkout_flow_trial_number
  end

  def purchase
    result = fetch("#{ASSISTED_CHECKOUT_HOST}/purchase", parms_for_purchase)

    puts "result from purchase:\n#{result.inspect}"
    assert_equal "success", result['response_code']

    validate_response(result['data'])
    self.order_number = fetch_order_number(result)
    assert_not_nil order_number
  end

  def validate_response(data)
    assert data['item_price'].to_f > 0
    assert data['tax'].to_f > 0
    assert data['shipping_cost'].to_f >= 0
    assert data['discount'].to_f >= 0
    assert data['order_total'].to_f > 0
  end

########### params below

  def parms
    {
      :checkout_id => checkout_id,
      :cookies => cookies
    }
  end

  def parms_for_fetch_detail
    parms.merge({
      :product_url => affiliate_url,
      :retailer => apparel_item_vendor_feed_path,
    })
  end

  def parms_for_add_to_bag
    parms.merge(item_hash).symbolize_keys
  end

  def parms_for_fetch_order_data
    parms_for_add_to_bag.merge(user_info_hash).merge(credit_card_hash).symbolize_keys
  end

  def parms_for_purchase
    {
      :checkout_flow_trial_number => self.checkout_flow_trial_number
    }.merge(parms_for_fetch_order_data)
  end

  def item_hash
    {
      :expected_description => apparel_item.description,
      :affiliate_url => affiliate_url,
      :vendor_key => apparel_item.vendor_key,
      :retailer => apparel_item_vendor_feed_path, ### stubbed

#      :url => "http://www1.bloomingdales.com/catalog/product/index.ognc?ID=455052",
#      :color_name => 'Silver',
#      :size_name => 'Small',
#      :vendor_scc_value => '798313',
#      :sale_price => '10.08'

      :url => apparel_item.product_url,
      :color_name => @sccs_info['color_name'],
      :size_name => @sccs_info['size_name'],
      :vendor_scc_value => @sccs_info['vendor_scc_value'],
      :sale_price => @sccs_info['sale_price'] # not sure if 'sale_price' info is necessary
    }
  end

  def user_info_hash
    @config[:user]
  end

  def credit_card_hash
    @config[:credit_card]
  end

end

BloomingdalesCheckoutIntegrationTest.new.run
