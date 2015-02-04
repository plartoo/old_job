$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'rubygems'
require 'mechanize'
require 'mechanize_extension'
require 'json'

require 'ruby-debug'
CREDIT_CARD_TYPE = {
  "american_express" => "AM",
  "visa" => "VC",
  "master" => "MC",
  "discover" => "DC",
}


@step = 0
## only used for testing purpose
def write_out_page(fname)
  File.open(fname,'w'){|f|
    f << "\n##################################################\n#{Time.now}\n\n\n"
    f << @page.content
  }
end

agent = Mechanize.new
agent.user_agent = "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.17) Gecko/20110422 Ubuntu/9.10 (karmic) Firefox/3.6.17"
url = "http://www.saksfifthavenue.com/main/ProductDetail.jsp?FOLDER%3C%3Efolder_id=2534374306418048&PRODUCT%3C%3Eprd_id=845524446407149&R=846632051481&P_name=Rebecca+Minkoff&N=1553+306418048"

@page = agent.get(url)

scc_div = @page.search("select[name='ADD_CART_ITEM_ARRAY<>sku_id'] option")
@sku_id = scc_div[1].attr('value') rescue nil

#### step 1
puts "Step 1: #{@page.title}"
write_out_page('step1.html')

fucking_add_to_bag = "http://www.saksfifthavenue.com/main/ProductDetail.jsp"

@product_code = @page.search("input[name='ADD_CART_ITEM_ARRAY<>productCode']").first.attr('value')
@bm_form_id = @page.search("input[name='bmFormID']").first.attr('value')
@bm_uid = @page.search("input[name='bmUID']").first.attr('value')
@prd_id = @page.search("input[name='PRODUCT<>prd_id']").first.attr('value')
@folder_id = @page.search("input[name='FOLDER<>folder_id']").first.attr('value')

items_in_bag_cookie = agent.cookies.select{|x| x.name == "saksBagNumberOfItems"}.first
pp items_in_bag_cookie

#if items_in_bag_cookie.nil? || items_in_bag_cookie.value == "0"
#  raise "Could not add item to shopping bag"
#end

parms = [
  ['ADD_CART_ITEM_ARRAY<>ATR_GiftWrapTypeCode', ''],
  ['ADD_CART_ITEM_ARRAY<>ATR_Returnable', 'TRUE'],
  ['ADD_CART_ITEM_ARRAY<>ATR_giftwrapmessage', ''],
  ['ADD_CART_ITEM_ARRAY<>prd_id', @prd_id],
  ['ADD_CART_ITEM_ARRAY<>productCode', @product_code],
  ['ADD_CART_ITEM_ARRAY<>qtyToBuy', '1'],
  ['ADD_CART_ITEM_ARRAY<>sku_id', @sku_id],

  ["PRODUCT<>prd_id", @prd_id],
  ["FOLDER<>folder_id", @folder_id],

  ['bmForm', 'saks_add_to_cart'],
  ['bmFormID', @bm_form_id],

  ['bmHidden', 'ADD_CART_ITEM_ARRAY<>prd_id'],
  ['bmHidden', 'ADD_CART_ITEM_ARRAY<>productCode'],
  ['bmHidden', 'ADD_CART_ITEM_ARRAY<>ATR_GiftWrapTypeCode'],
  ['bmHidden', 'ADD_CART_ITEM_ARRAY<>ATR_giftwrapmessage'],
  ['bmHidden', 'ADD_CART_ITEM_ARRAY<>ATR_Returnable'],
  ['bmHidden', 'PRODUCT<>prd_id'],
  ['bmHidden', 'FOLDER<>folder_id'],

  ['bmImage', 'checkout.x'],
  ['bmImage', 'checkout.y'],
  ['bmImage', 'checkout'],
  ['bmImage', 'checkoutPers.x'],
  ['bmImage', 'checkoutPers.y'],
  ['bmImage', 'checkoutPers'],
  ['bmIsForm', 'TRUE'],
  ['bmPrevTemplate', '/main/ProductDetail.jsp'],
  ['bmRequired', 'ADD_CART_ITEM_ARRAY<>qtyToBuy'],
  ['bmSingle', 'ADD_CART_ITEM_ARRAY<>sku_id'],
  ['bmText', 'ADD_CART_ITEM_ARRAY<>qtyToBuy'],
  ['bmUID', @bm_uid],
  ['checkout.x', 33],
  ['checkout.y', 12]
]

@page = agent.post(fucking_add_to_bag, parms)
puts "Step 2: #{@page.title}"
write_out_page('step2.html')

saks_bag_post = "https://www.saksfifthavenue.com/checkout/SaksBag.jsp"
parms = {
  'bmForm' => 'initialize_saks_bag_service',
}

debugger
@page = agent.post(saks_bag_post, parms)
puts "Step 3: #{@page.title}"
write_out_page('step3.html')
json_data = JSON.parse(@page.content)






