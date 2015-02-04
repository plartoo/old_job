$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'rubygems'
require 'ruby-debug'
require 'rake'
require 'fileutils'
require 'rake/rdoctask'
require 'logger'
require 'mechanize'


Dir.glob('tasks/*.rake').each { |r| import r }

Rake.application.options.trace = true

desc <<-EOD
  PRODUCT_URL="url"                             : The item's product url

  SCC_STRING="TITANIUM\302\240\302\240\302\24037/7 C" : The actual string text that shows up for the select element
  SCC_VALUE="1689949377299738"                  : The product code for the selected size/color config
  Either SCC_VALUE or SCC_STRING is necessary

  EXPECTED_ITEM_PRICE="150.00"                       :What we expect the price to be
  ZIP_CODE="90210"            : User zip code
  EXPECTED_SHIPPING="14.50"
  EXPECTED_TOTAL_PRICE="204.99:
  USER_EMAIL_ADDRESS="phyo@xxxxx.com"
EOD
task :checkout do
  product_url = ENV['PRODUCT_URL']
  scc_string = ENV['SCC_STRING'] ? ENV['SCC_STRING'].gsub(/\\/,'\\') : nil
  scc_value = ENV['SCC_VALUE']
  expected_item_price = ENV['EXPECTED_ITEM_PRICE']
  expected_vendor_key = ENV['VENDOR_KEY']
  expected_description = ENV['DESCRIPTION']
  user_zip_code = ENV['ZIP_CODE']
  user_email_address = ENV['USER_EMAIL_ADDRESS']

  expected_shipping = ENV['EXPECTED_SHIPPING']
  expected_total_price = ENV['EXPECTED_TOTAL_PRICE']
  expected_tax = ENV['EXPECTED_TAX']

  #### Expand this to verify the args
  raise "No product url given" if product_url.nil?
  raise "SCC selection not provided" if (scc_value.nil? && scc_string.nil?)
  raise "No expected price given" if expected_item_price.nil?

  require 'json'


  agent = WWW::Mechanize.new
  agent.user_agent = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:2.0.1) Gecko/20100101 Firefox/4.0.1"
#  agent.log = Logger.new(STDOUT)

  puts "Getting product detail page"
  prod_page = agent.get(product_url)

  size_options = prod_page.search("select[name='ADD_CART_ITEM_ARRAY<>sku_id'] option")
  size_options.each{|x| puts x.text}
  debugger
  if scc_string
    size_config_prod_code = size_options.select{|x| x.text.match(/#{scc_string}/)}.first.attr('value') rescue nil
  elsif scc_value
    size_config_prod_code = scc_value
  end

  raise "Invalid size config prod code" if size_config_prod_code.nil?

  hidden_form_vals = prod_page.search("form[name='saks_add_to_cart'] input").map{|element|
    [element.attr('name'),element.attr('value')]
  }
  hidden_form_vals << ["ADD_CART_ITEM_ARRAY<>sku_id",size_config_prod_code]
  hidden_form_vals << ["checkout.x",7]
  hidden_form_vals << ["checkout.y",8]

  POST_REQUEST_URL = "http://www.saksfifthavenue.com/main/ProductDetail.jsp"
  agent.post(POST_REQUEST_URL, hidden_form_vals)

  items_in_bag_cookie = agent.cookies.select{|x| x.name == "saksBagNumberOfItems"}.first
  if items_in_bag_cookie.nil? || items_in_bag_cookie.value == "0"
    raise "Could not add item to shopping bag"
  end

  VERIFY_SHOPPING_CART_CONTENTS_URL = "https://www.saksfifthavenue.com/checkout/SaksBag.jsp"
  shopping_cart_ssl_page = agent.get(VERIFY_SHOPPING_CART_CONTENTS_URL)

  shopping_cart_json = agent.post(VERIFY_SHOPPING_CART_CONTENTS_URL,
                                  [["bmForm","initialize_saks_bag_service"]],
                                  {"X-Requested-With" => "XMLHttpRequest",
                                    "Accept" => "application/json"
                                  }
                                )
  json_data = JSON::parse(shopping_cart_json.content)
  to_verify = [
    {:field => json_data["cartSummary"]["itemsTotal"].match(/([\d\,\.]+)$/), :expected => expected_item_price, :error => "Expected price does not match"},
    {:field => json_data["cartItems"].first["productDetailUrl"].match(/prd_id=(\d+)/), :expected => expected_vendor_key, :error => "Expected vendor_key does not match."},
    {:field => json_data["cartItems"].first["shortDescription"], :expected => expected_description, :error => "Expected description does not match"},
    {:field => json_data["cartItems"].first["UPCId"], :expected => size_config_prod_code, :error => "Expected UPC sku does not match"},
  ].each do |data|
    present = data[:field].is_a?(MatchData) ? data[:field][1] : data[:field] rescue nil
    unless present == data[:expected]
      raise data[:error]
    end
  end

  # verify shipping based on zip code
  shipping_method_id = json_data["shippingMethods"].first["id"]
  CHECK_ZIP_CODE_URL = "https://www.saksfifthavenue.com/checkout/checkout.jsp"
  final_total_json = agent.post(CHECK_ZIP_CODE_URL,
                                  [["bmForm","update_cart_summary_service"],
                                   ["selectedMethodId",shipping_method_id],
                                   ["zipCode", user_zip_code]
    ],
                                  {"X-Requested-With" => "XMLHttpRequest",
                                    "Accept" => "application/json",
                                  }
                                )

  final_total_json = JSON.parse(final_total_json.content)


  to_verify = [
    {:field => final_total_json["cartSummary"]["tax"].match(/([\d\,\.]+)$/), :expected => expected_tax, :error => "Expected tax does not match"},
    {:field => final_total_json["cartSummary"]["shippingCost"].match(/([\d\,\.]+)$/), :expected => expected_shipping, :error => "Expected shipping does not match"},
    {:field => final_total_json["cartSummary"]["grandTotal"].match(/([\d\,\.]+)$/), :expected => expected_total_price, :error => "Expected total price does not match"},
  ].each do |data|
    present = data[:field].is_a?(MatchData) ? data[:field][1] : data[:field] rescue nil
    unless present == data[:expected]
      raise data[:error]
    end
  end

  agent.get("https://www.saksfifthavenue.com/checkout/checkout.jsp#init1")

  LOGIN_AS_GUEST_URL = "https://www.saksfifthavenue.com/checkout/checkout.jsp#init1"
  login_as_user_page = agent.post(LOGIN_AS_GUEST_URL,
                                  [["bmForm","login_as_guest_user"],
                                   ["LOGIN<>userid",CGI.escape(user_email_address)],
    ],
                                  {"X-Requested-With" => "XMLHttpRequest",
                                    "Accept" => "application/json",
                                  }
                                )
  checkout_page = agent.get("https://www.saksfifthavenue.com/checkout/SaksBag.jsp?failure=true&flcxtpqrz=0")
#  final_total_json = JSON.parse(login_as_user.content)

  SHIPPING_ADDRESS_PAGE_URL = "https://www.saksfifthavenue.com/checkout/checkout.jsp"
  shipping_address_page = agent.post(SHIPPING_ADDRESS_PAGE_URL,
                                  [["bmForm","validate_ship_address_service"],
                                   ["SHIP_TO_ADDRESS<>address1", "410 Townsend St., Suite 150"],
                                   ["SHIP_TO_ADDRESS<>address2",	""],
                                   ["SHIP_TO_ADDRESS<>address3",	"Shop It To Me, Inc."],
                                   ["SHIP_TO_ADDRESS<>city",	"San Francisco"],
                                   ["SHIP_TO_ADDRESS<>indGift",	"4"],
                                   ["SHIP_TO_ADDRESS<>firstName",	"Saks"],
                                   ["SHIP_TO_ADDRESS<>lastName",	"Avenue"],
                                   ["SHIP_TO_ADDRESS<>middleName",	"J"],
                                   ["SHIP_TO_ADDRESS<>phone",	"607-911-3265"],
                                   ["SHIP_TO_ADDRESS<>postal",	"94107"],
                                   ["SHIP_TO_ADDRESS<>state_cd",	"CA"],
                                   ["SHIP_TO_ADDRESS<>uad_id", ""],
                                   ["count",	"1"],
                                   ["setAsBillAddress", "true"],
                                   ["shiptomult",	"false"],
                                  ],
                                  {"X-Requested-With" => "XMLHttpRequest",
                                    "Accept" => "application/json",
                                  }
                                )
  shipping_address_page_response = JSON.parse(shipping_address_page.content)
  if shipping_address_page_response["errors"]
    raise shipping_address_page_response["errors"].map{|x| x["message"]}.join(" ")
  elsif shipping_address_page_response["verifyLevel"] != "Verified"
    raise shipping_address_page_response.map{|x| x["message"]}.join(" ")
  end

  SHIPPING_ADDRESS_PAGE_CONTINUE_URL = "https://www.saksfifthavenue.com/checkout/checkout.jsp"
  shipping_address_continue_page = agent.post(SHIPPING_ADDRESS_PAGE_CONTINUE_URL,
                                  [["bmForm","add_address_and_continue_service"],
                                   ["SHIP_TO_ADDRESS<>address1", "410 Townsend St., Suite 150"],
                                   ["SHIP_TO_ADDRESS<>address2",	""],
                                   ["SHIP_TO_ADDRESS<>address3",	"Shop It To Me, Inc."],
                                   ["SHIP_TO_ADDRESS<>city",	"San Francisco"],
                                   ["SHIP_TO_ADDRESS<>indGift",	"4"],
                                   ["SHIP_TO_ADDRESS<>firstName",	"Saks"],
                                   ["SHIP_TO_ADDRESS<>lastName",	"Avenue"],
                                   ["SHIP_TO_ADDRESS<>middleName",	"J"],
                                   ["SHIP_TO_ADDRESS<>phone",	"607-911-3265"],
                                   ["SHIP_TO_ADDRESS<>postal",	"94107"],
                                   ["SHIP_TO_ADDRESS<>state_cd",	"CA"],
                                   ["SHIP_TO_ADDRESS<>uad_id", ""],
                                   ["count",	"1"],
                                   ["setAsBillAddress", "true"],
                                   ["shiptomult",	"false"],
                                  ],
                                  {"X-Requested-With" => "XMLHttpRequest",
                                    "Accept" => "application/json",
                                  }
                                )
  shipping_address_continue_page_response = JSON.parse(shipping_address_continue_page.content)
  if shipping_address_continue_page_response["errors"]
    raise shipping_address_continue_page_response["errors"].map{|x| x["message"]}.join(" ")
  elsif shipping_address_continue_page_response["verifyLevel"] && shipping_address_continue_page_response["verifyLevel"] != "Verified"
    raise shipping_address_continue_page_response.map{|x| x["message"]}.join(" ")
  end

  VERIFY_CREDIT_CARD_CONTINUE_URL = "https://www.saksfifthavenue.com/checkout/checkout.jsp"
  verify_credit_card_continue = agent.post(VERIFY_CREDIT_CARD_CONTINUE_URL,
                                  [["bmForm","submit_payment_service"],
                                    ["ACCOUNT<>accountNumber", ""],
                                    ["ACCOUNT<>notificationEmail", ""],
                                    ["CREDIT_CARD<>cardBrand_cd",	"VISA"],
                                    ["CREDIT_CARD<>cardMonth_cd", 2],
                                    ["CREDIT_CARD<>cardNum",	"4122323212345698"],
                                    ["CREDIT_CARD<>cardYear_cd",	"2014"],
                                    ["CREDIT_CARD<>cardholderName",	"Not American Express"],
                                    ["USER_ACCOUNT<>ATR_passwordHint"	, ""],
                                    ["USER_ACCOUNT<>confirmPassword", ""],
                                    ["USER_ACCOUNT<>password", ""],
                                    ["card_cvNumber",	"999"],
                                    ["promoCode",""],
                                  ],
                                  {"X-Requested-With" => "XMLHttpRequest",
                                    "Accept" => "application/json",
                                  }
                                )


  verify_credit_card_continue_response = JSON.parse(verify_credit_card_continue.content)
  if verify_credit_card_continue_response["creditCardList"]
    verify_credit_card_continue_response["creditCardList"].each do |k,v|
      raise "#{k} is missing" if v.nil?
    end
  elsif verify_credit_card_continue_response["errors"]
    raise verify_credit_card_continue_response["errors"].map{|x| x["message"]}.join(" ")
  end

  # 
  SUBMIT_CREDIT_CARD_CONTINUE_URL = "https://www.saksfifthavenue.com/checkout/checkout.jsp"
  submit_credit_card_continue = agent.post(SUBMIT_CREDIT_CARD_CONTINUE_URL,
                                  [["bmForm","submit_order_service"],
#                                    ["ACCOUNT<>accountNumber", ""],
#                                    ["ACCOUNT<>notificationEmail", ""],
#                                    ["CREDIT_CARD<>cardBrand_cd",	"VISA"],
#                                    ["CREDIT_CARD<>cardMonth_cd", 2],
#                                    ["CREDIT_CARD<>cardNum",	"4122323212345698"],
#                                    ["CREDIT_CARD<>cardYear_cd",	"2014"],
#                                    ["CREDIT_CARD<>cardholderName",	"Not American Express"],
#                                    ["USER_ACCOUNT<>ATR_passwordHint"	, ""],
#                                    ["USER_ACCOUNT<>confirmPassword", ""],
#                                    ["USER_ACCOUNT<>password", ""],
#                                    ["card_cvNumber",	"999"],
#                                    ["promoCode",""],
                                  ],
                                  {"X-Requested-With" => "XMLHttpRequest",
                                    "Accept" => "application/json",
                                  }
                                )


  submit_credit_card_continue_response = JSON.parse(submit_credit_card_continue.content)
  if submit_credit_card_continue_response["creditCardList"]
    submit_credit_card_continue_response["creditCardList"].each do |k,v|
      raise "#{k} is missing" if v.nil?
    end
  elsif submit_credit_card_continue_response["errors"]
    raise submit_credit_card_continue_response["errors"].map{|x| x["message"]}.join(" ")
  end


  1



end

class WWW::Mechanize
  def post(url, query= {}, headers = {})
    node = {}
    # Create a fake form
    class << node
      def search(*args); []; end
    end
    node['method'] = 'POST'
    node['enctype'] = 'application/x-www-form-urlencoded'

    form = Form.new(node)
    query.each { |k,v|
      if v.is_a?(IO)
        form.enctype = 'multipart/form-data'
        ul = Form::FileUpload.new(k.to_s,::File.basename(v.path))
        ul.file_data = v.read
        form.file_uploads << ul
      else
        form.fields << Form::Field.new(k.to_s,v)
      end
    }
    post_form(url, form, headers)
  end
end

