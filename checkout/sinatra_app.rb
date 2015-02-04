require 'rubygems'
require 'bundler/setup'

$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'json'
require 'sinatra'

require 'checkout_manager'
require 'checkout_manager_error'
require 'mechanize_checkout_manager'
require 'mechanize_extension'

require 'vendor/always_verify_ssl_certificates/lib/always_verify_ssl_certificates'


class SinatraApp < Sinatra::Application

  SCREENSHOT_FOLDER = File.join(File.expand_path(File.dirname(__FILE__)),"screenshots")
  FileUtils::mkdir_p SCREENSHOT_FOLDER

  get '/fetch_detail' do
    fetch_detail.to_json
  end

  post '/fetch_detail' do
    fetch_detail.to_json
  end

  get '/add_to_bag' do
    run_task(:add_to_bag).to_json
  end

  post '/add_to_bag' do
    run_task(:add_to_bag).to_json
  end

  get '/fetch_order_data' do
    run_task(:fetch_order_data).to_json
  end

  post '/fetch_order_data' do
    run_task(:fetch_order_data).to_json
  end

  get '/purchase' do
    run_task(:purchase).to_json
  end

  post '/purchase' do
    run_task(:purchase).to_json
  end

  get '/test_fetch_detail_s' do
    html = "<form method=\"post\" action=\"/fetch_detail\">"
    html += "retailer: <input type='text' name='retailer' value='saksfifthavenue' size='60' />"
    html += "<br /><br />checkout_id: <input type='text' name='checkout_id' value='rootyroot_fetch_detail' size='40' />"
    html += "<br /><br />product_url: <input type='text' name='product_url' value='http://www.saksfifthavenue.com/main/ProductDetail.jsp?FOLDER%3C%3Efolder_id=2534374306418048&PRODUCT%3C%3Eprd_id=845524446404604&R=845924025902&P_name=Acne&N=1553+306418048&bmUID=j6M5bdc' size='60' />"
    html += "<br /><br /><input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  get '/test_add_to_bag_s' do
    html = "<form method=\"post\" action=\"/add_to_bag\">"
    html += "retailer: <input type='text' name='retailer' value='saksfifthavenue' size='60' />"
    html += "<br /><br />checkout_id (IGNORE: This is unique ID for this checkout passed in by Jeremy): <input type='text' name='checkout_id' value='rootyroot_add_to_bag' size='60' />"
    html += "<br /><br />product_url: <input type='text' name='url' value='http://www.saksfifthavenue.com/main/ProductDetail.jsp?FOLDER%3C%3Efolder_id=2534374306418048&PRODUCT%3C%3Eprd_id=845524446404604&R=845924025902&P_name=Acne&N=1553+306418048&bmUID=j6M5bdc' size='60' />"
    html += "<br /><br />affiliate_url: <input type='text' name='affiliate_url' value='http://www.saksfifthavenue.com/main/ProductDetail.jsp?FOLDER%3C%3Efolder_id=2534374306418048&PRODUCT%3C%3Eprd_id=845524446404604&R=845924025902&P_name=Acne&N=1553+306418048&bmUID=j6M5bdc' size='60' />"

    html += "<br /><br />sku_id: <input type='text' name='sku_id' value='1689949377189947' size='60' />"

    html += "<input type='hidden' name='testing' value='true' size='60' />"
    html += "<input type='hidden' name='email_address' value='phyo@xxxx.com' size='60' />"
    html += "<br /><br /><input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  get '/test_fetch_order_data_s' do
    html = "<form method=\"post\" action=\"/fetch_order_data\">"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />first_name: <input type='text' name='first_name' value='Alice' size='40' />"
    html += "<br /><br />last_name: <input type='text' name='last_name' value='Lee' size='40' />"
    html += "<br /><br />address_1: <input type='text' name='address_1' value='410 Townsend St.' size='40' />"
    html += "<br /><br />address_2: <input type='text' name='address_2' value='Ste 150' size='40' />"
    html += "<br /><br />city: <input type='text' name='city' value='San Francisco' size='40' />"
    html += "<br /><br />state: <input type='text' name='state' value='CA' size='40' />"
    html += "<br /><br />zip: <input type='text' name='zip' value='94107' size='40' />"
    html += "<br /><br />phone: <input type='text' name='phone' value='415-796-0031' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />separate_billing_address: <input type='text' name='separate_billing_address' value='true' size='40' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />billing_first_name: <input type='text' name='billing_first_name' value='Charles' size='40' />"
    html += "<br /><br />billing_last_name: <input type='text' name='billing_last_name' value='Graham' size='40' />"
    html += "<br /><br />billing_address_1: <input type='text' name='billing_address_1' value='3467 Fillmore St' size='40' />"
    html += "<br /><br />billing_address_2: <input type='text' name='billing_address_2' value='' size='40' />"
    html += "<br /><br />billing_city: <input type='text' name='billing_city' value='San Francisco' size='40' />"
    html += "<br /><br />billing_state: <input type='text' name='billing_state' value='CA' size='40' />"
    html += "<br /><br />billing_country: <input type='text' name='billing_country' value='NOT BEING USED' size='40' />"
    html += "<br /><br />billing_zip: <input type='text' name='billing_zip' value='94123' size='40' />"
    html += "<br /><br />billing_phone: <input type='text' name='billing_phone' value='415-796-0031' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />email_address: <input type='text' name='email_address' value='phyo@xxxx.com' size='40' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />credit_card_type: <input type='text' name='credit_card_type' value='visa' size='40' />"
    html += "<br /><br />credit_card_num: <input type='text' name='credit_card_num' value='4111111111111111' size='40' />"
    html += "<br /><br />credit_card_month: <input type='text' name='credit_card_month' value='11' size='40' />"
    html += "<br /><br />credit_card_year: <input type='text' name='credit_card_year' value='2012' size='40' />"
    html += "<br /><br />credit_card_ccv: <input type='text' name='credit_card_ccv' value='255' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />url: <input type='text' name='url' value='http://www.saksfifthavenue.com/main/ProductDetail.jsp?FOLDER%3C%3Efolder_id=2534374306418048&PRODUCT%3C%3Eprd_id=845524446404604&R=845924025902&P_name=Acne&N=1553+306418048&bmUID=j6M5bdc' size='40' />"
    html += "<br /><br />affiliate_url: <input type='text' name='affiliate_url' value='http://www.saksfifthavenue.com/main/ProductDetail.jsp?FOLDER%3C%3Efolder_id=2534374306418048&PRODUCT%3C%3Eprd_id=845524446404604&R=845924025902&P_name=Acne&N=1553+306418048&bmUID=j6M5bdc' size='60' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />expected_description: <input type='text' name='expected_description' value='Suede-Tie Tank Dress' size='40' />"
    html += "<br /><br />sku_id: <input type='text' name='sku_id' value='1689949377189947' size='60' />"
    html += "retailer: <input type='text' name='retailer' value='saksfifthavenue' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />testing (ignore this as a tester): <input type='text' name='testing' value='true' size='40' />"
    html += "<br /><br /><input type='hidden' name='checkout_id' value='rootyroot_fetch_order_data' size='40' />"
    html += "</div>"

    [].each do |field|

      html += "<br /><br />#{field}: <input type='text' name='#{field}' size='100' />"
    end

    html += "<br /><br /><input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  get '/test_purchase_s' do
    html = "<form method=\"post\" action=\"/purchase\">"
    html += "retailer: <input type='text' name='retailer' value='saksfifthavenue' size='60' />"

    html += "<div>"
    html += "<br /><br />checkout_id (ignore this as a tester. This is unique ID for this checkout passed in by Jeremy): <input type='text' name='checkout_id' value='rootyroot_purchase' size='60' />"
    html += "<br /><br /><input type='hidden' name='testing' value='true' size='40' />"

    html += "<br /><br />Only needed for Saks to remove from bag."

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />first_name: <input type='text' name='first_name' value='Alice' size='40' />"
    html += "<br /><br />last_name: <input type='text' name='last_name' value='Lee' size='40' />"
    html += "<br /><br />address_1: <input type='text' name='address_1' value='410 Townsend St.' size='40' />"
    html += "<br /><br />address_2: <input type='text' name='address_2' value='Ste 150' size='40' />"
    html += "<br /><br />city: <input type='text' name='city' value='San Francisco' size='40' />"
    html += "<br /><br />state: <input type='text' name='state' value='CA' size='40' />"
    html += "<br /><br />zip: <input type='text' name='zip' value='94107' size='40' />"
    html += "<br /><br />phone: <input type='text' name='phone' value='415-796-0031' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />separate_billing_address: <input type='text' name='separate_billing_address' value='true' size='40' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />billing_first_name: <input type='text' name='billing_first_name' value='Charles' size='40' />"
    html += "<br /><br />billing_last_name: <input type='text' name='billing_last_name' value='Graham' size='40' />"
    html += "<br /><br />billing_address_1: <input type='text' name='billing_address_1' value='3467 Fillmore St' size='40' />"
    html += "<br /><br />billing_address_2: <input type='text' name='billing_address_2' value='' size='40' />"
    html += "<br /><br />billing_city: <input type='text' name='billing_city' value='San Francisco' size='40' />"
    html += "<br /><br />billing_state: <input type='text' name='billing_state' value='CA' size='40' />"
    html += "<br /><br />billing_country: <input type='text' name='billing_country' value='NOT BEING USED' size='40' />"
    html += "<br /><br />billing_zip: <input type='text' name='billing_zip' value='94123' size='40' />"
    html += "<br /><br />billing_phone: <input type='text' name='billing_phone' value='415-796-0031' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />email_address: <input type='text' name='email_address' value='phyo@xxxx.com' size='40' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />credit_card_type: <input type='text' name='credit_card_type' value='visa' size='40' />"
    html += "<br /><br />credit_card_num: <input type='text' name='credit_card_num' value='4111111111111111' size='40' />"
    html += "<br /><br />credit_card_month: <input type='text' name='credit_card_month' value='11' size='40' />"
    html += "<br /><br />credit_card_year: <input type='text' name='credit_card_year' value='2012' size='40' />"
    html += "<br /><br />credit_card_ccv: <input type='text' name='credit_card_ccv' value='255' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />url: <input type='text' name='url' value='http://www.saksfifthavenue.com/main/ProductDetail.jsp?FOLDER%3C%3Efolder_id=2534374306418048&PRODUCT%3C%3Eprd_id=845524446404604&R=845924025902&P_name=Acne&N=1553+306418048&bmUID=j6M5bdc' size='40' />"
    html += "<br /><br />affiliate_url: <input type='text' name='affiliate_url' value='http://www.saksfifthavenue.com/main/ProductDetail.jsp?FOLDER%3C%3Efolder_id=2534374306418048&PRODUCT%3C%3Eprd_id=845524446404604&R=845924025902&P_name=Acne&N=1553+306418048&bmUID=j6M5bdc' size='60' />"
    html += "</div>"

    html += "<br /><br />sku_id: <input type='text' name='sku_id' value='1689949377189947' size='60' />"

    html += "</div>"

    html += "<br /><br />Make sure you have the cookie file<input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  get '/test_fetch_detail_b' do
    html = "<form method=\"post\" action=\"/fetch_detail\">"
    html += "retailer: <input type='text' name='retailer' value='bluefly' size='60' />"
    html += "<br /><br />checkout_id: <input type='text' name='checkout_id' value='rootyroot_fetch_detail' size='40' />"
    html += "<br /><br />product_url: <input type='text' name='product_url' value='http://www.bluefly.com/Burberry-Burberry-London-white-stretch-cotton-blouse/cat20020/316159101/detail.fly' size='60' />"
    html += "<br /><br /><input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  get '/test_add_to_bag_b' do
    html = "<form method=\"post\" action=\"/add_to_bag\">"
    html += "retailer: <input type='text' name='retailer' value='bluefly' size='60' />"
    html += "<br /><br />checkout_id (IGNORE: This is unique ID for this checkout passed in by Jeremy): <input type='text' name='checkout_id' value='rootyroot_add_to_bag' size='60' />"
    html += "<br /><br />product_url: <input type='text' name='url' value='http://www.bluefly.com/Wyatt-navy-chiffon-v-neck-pleated-placket-blouse/cat20020/313621601/detail.fly' size='60' />"
    html += "<br /><br />affiliate_url: <input type='text' name='affiliate_url' value='http://www.bluefly.com/Wyatt-navy-chiffon-v-neck-pleated-placket-blouse/cat20020/313621601/detail.fly' size='60' />"

    html += "<br /><br />catalog_ref_id: <input type='text' name='catalog_ref_id' value='891948930739' size='60' />"

    html += "<input type='hidden' name='testing' value='true' size='60' />"
    html += "<br /><br /><input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  get '/test_fetch_order_data_b' do
    html = "<form method=\"post\" action=\"/fetch_order_data\">"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />first_name: <input type='text' name='first_name' value='Alice' size='40' />"
    html += "<br /><br />last_name: <input type='text' name='last_name' value='Lee' size='40' />"
    html += "<br /><br />address_1: <input type='text' name='address_1' value='410 Townsend St.' size='40' />"
    html += "<br /><br />address_2: <input type='text' name='address_2' value='Ste 150' size='40' />"
    html += "<br /><br />city: <input type='text' name='city' value='San Francisco' size='40' />"
    html += "<br /><br />state: <input type='text' name='state' value='CA' size='40' />"
    html += "<br /><br />zip: <input type='text' name='zip' value='94107' size='40' />"
    html += "<br /><br />phone: <input type='text' name='phone' value='415-796-0031' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />separate_billing_address: <input type='text' name='separate_billing_address' value='true' size='40' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />billing_first_name: <input type='text' name='billing_first_name' value='Charles' size='40' />"
    html += "<br /><br />billing_last_name: <input type='text' name='billing_last_name' value='Graham' size='40' />"
    html += "<br /><br />billing_address_1: <input type='text' name='billing_address_1' value='3467 Fillmore St' size='40' />"
    html += "<br /><br />billing_address_2: <input type='text' name='billing_address_2' value='' size='40' />"
    html += "<br /><br />billing_city: <input type='text' name='billing_city' value='San Francisco' size='40' />"
    html += "<br /><br />billing_state: <input type='text' name='billing_state' value='CA' size='40' />"
    html += "<br /><br />billing_country: <input type='text' name='billing_country' value='NOT BEING USED' size='40' />"
    html += "<br /><br />billing_zip: <input type='text' name='billing_zip' value='94123' size='40' />"
    html += "<br /><br />billing_phone: <input type='text' name='billing_phone' value='415-796-0031' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />email_address: <input type='text' name='email_address' value='phyo@xxxx.com' size='40' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />credit_card_type: <input type='text' name='credit_card_type' value='visa' size='40' />"
    html += "<br /><br />credit_card_num: <input type='text' name='credit_card_num' value='4111111111111111' size='40' />"
    html += "<br /><br />credit_card_month: <input type='text' name='credit_card_month' value='11' size='40' />"
    html += "<br /><br />credit_card_year: <input type='text' name='credit_card_year' value='2012' size='40' />"
    html += "<br /><br />credit_card_ccv: <input type='text' name='credit_card_ccv' value='255' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />url: <input type='text' name='url' value='http://www.bluefly.com/Wyatt-navy-chiffon-v-neck-pleated-placket-blouse/cat20020/313621601/detail.fly' size='40' />"
    html += "<br /><br />affiliate_url: <input type='text' name='affiliate_url' value='http://www.bluefly.com/Wyatt-navy-chiffon-v-neck-pleated-placket-blouse/cat20020/313621601/detail.fly' size='60' />"
    html += "<br /><br />dyn_sess_conf: <input type='text' name='dyn_sess_conf' value='' size='60' />"
    html += "<br /><br />remove_id_1: <input type='text' name='remove_id_1' value='' size='60' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />expected_description: <input type='text' name='expected_description' value='Wyatt navy chiffon v-neck pleated placket blouse ' size='40' />"
    html += "retailer: <input type='text' name='retailer' value='bluefly' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />testing (ignore this as a tester): <input type='text' name='testing' value='true' size='40' />"
    html += "<br /><br /><input type='hidden' name='checkout_id' value='rootyroot_fetch_order_data' size='40' />"
    html += "</div>"

    [].each do |field|

      html += "<br /><br />#{field}: <input type='text' name='#{field}' size='100' />"
    end

    html += "<br /><br /><input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  get '/test_purchase_b' do
    html = "<form method=\"post\" action=\"/purchase\">"
    html += "retailer: <input type='text' name='retailer' value='bluefly' size='60' />"

    html += "<div>"
    html += "<br /><br />checkout_id (ignore this as a tester. This is unique ID for this checkout passed in by Jeremy): <input type='text' name='checkout_id' value='rootyroot_purchase' size='60' />"
    html += "<br /><br /><input type='hidden' name='testing' value='true' size='40' />"
    html += "<br /><br />Only needed for Bluefly."
    html += "<br /><br />dyn_sess_conf: <input type='text' name='dyn_sess_conf' value='' size='60' />"
    html += "<br /><br />remove_id_1: <input type='text' name='remove_id_1' value='' size='60' />"
    html += "</div>"

    html += "<br /><br />Make sure you have the cookie file<input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  #######################

  get '/test_fetch_detail' do
    html = "<form method=\"post\" action=\"/fetch_detail\">"
    html += "retailer: <input type='text' name='retailer' value='macys' size='60' />"
    html += "<br /><br />checkout_id: <input type='text' name='checkout_id' value='rootyroot_fetch_detail' size='40' />"
    html += "<br /><br />product_url: <input type='text' name='product_url' value='http://www1.macys.com/catalog/product/index.ognc?ID=539672' size='60' />"
    html += "<br /><br />vendor_key: <input type='text' name='vendor_key' value='531820' size='60' />"

    html += "<br /><br /><input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  get '/test_add_to_bag' do
    html = "<form method=\"post\" action=\"/add_to_bag\">"
    html += "retailer: <input type='text' name='retailer' value='macys' size='60' />"
    html += "<br /><br />checkout_id (IGNORE: This is unique ID for this checkout passed in by Jeremy): <input type='text' name='checkout_id' value='rootyroot_add_to_bag' size='60' />"
    html += "<br /><br />product_url: <input type='text' name='url' value='http://www1.macys.com/catalog/product/index.ognc?ID=539672' size='60' />"
    html += "<br /><br />affiliate_url: <input type='text' name='affiliate_url' value='http://www1.macys.com/catalog/product/index.ognc?ID=539672' size='60' />"
    html += "<br /><br />color_name: <input type='text' name='color_name' value='Rattan' size='60' />"
    html += "<br /><br />size_name: <input type='text' name='size_name' value='12' size='60' />"
    html += "<input type='hidden' name='testing' value='true' size='60' />"

    html += "<br /><br /><input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  get '/test_purchase' do
    html = "<form method=\"post\" action=\"/purchase\">"
    html += "retailer: <input type='text' name='retailer' value='macys' size='60' />"

    html += "<div>"
    html += "<br /><br />checkout_id (ignore this as a tester. This is unique ID for this checkout passed in by Jeremy): <input type='text' name='checkout_id' value='rootyroot_purchase' size='60' />"
    html += "<br /><br /><input type='hidden' name='testing' value='true' size='40' />"
    html += "</div>"

    html += "<br /><br />Make sure you have the cookie file<input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  get '/test_fetch_order_data' do
    html = "<form method=\"post\" action=\"/fetch_order_data\">"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />first_name: <input type='text' name='first_name' value='Alice' size='40' />"
    html += "<br /><br />last_name: <input type='text' name='last_name' value='Lee' size='40' />"
    html += "<br /><br />address_1: <input type='text' name='address_1' value='410 Townsend St.' size='40' />"
    html += "<br /><br />address_2: <input type='text' name='address_2' value='Ste 150' size='40' />"
    html += "<br /><br />city: <input type='text' name='city' value='San Francisco' size='40' />"
    html += "<br /><br />state: <input type='text' name='state' value='CA' size='40' />"
    html += "<br /><br />zip: <input type='text' name='zip' value='94107' size='40' />"
    html += "<br /><br />phone: <input type='text' name='phone' value='415-796-0031' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />separate_billing_address: <input type='text' name='separate_billing_address' value='true' size='40' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />billing_first_name: <input type='text' name='billing_first_name' value='Charles' size='40' />"
    html += "<br /><br />billing_last_name: <input type='text' name='billing_last_name' value='Graham' size='40' />"
    html += "<br /><br />billing_address_1: <input type='text' name='billing_address_1' value='3467 Fillmore St' size='40' />"
    html += "<br /><br />billing_address_2: <input type='text' name='billing_address_2' value='' size='40' />"
    html += "<br /><br />billing_city: <input type='text' name='billing_city' value='San Francisco' size='40' />"
    html += "<br /><br />billing_state: <input type='text' name='billing_state' value='CA' size='40' />"
    html += "<br /><br />billing_country: <input type='text' name='billing_country' value='NOT BEING USED' size='40' />"
    html += "<br /><br />billing_zip: <input type='text' name='billing_zip' value='94123' size='40' />"
    html += "<br /><br />billing_phone: <input type='text' name='billing_phone' value='415-796-0031' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />email_address: <input type='text' name='email_address' value='phyo@xxxx.com' size='40' />"
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />credit_card_type: <input type='text' name='credit_card_type' value='Visa' size='40' />"
    html += "<br /><br />credit_card_num: <input type='text' name='credit_card_num' value='4147735702533164' size='40' />"
    html += "<br /><br />credit_card_month: <input type='text' name='credit_card_month' value='11' size='40' />"
    html += "<br /><br />credit_card_year: <input type='text' name='credit_card_year' value='2011' size='40' />"
    html += "<br /><br />credit_card_ccv: <input type='text' name='credit_card_ccv' value='255' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />url: <input type='text' name='url' value='http://www1.macys.com/catalog/product/index.ognc?ID=539672' size='40' />"
    html += "<br /><br />affiliate_url: <input type='text' name='affiliate_url' value='http://www1.macys.com/catalog/product/index.ognc?ID=539672' size='60' />"
    html += "<br /><br />Final Category Path (from detail page scraping): <input type='text' name='coremetricsDepthPath' value='Leggings' size='40' />" # from detail page <input id="coremetricsDepthPath">
    html += "<br /><br />Size Name (from detail page scraping): <input type='text' name='size_name' value='12' size='40' />"
    html += "<br /><br />Color Name (from detail page scraping): <input type='text' name='color_name' value='Rattan' size='40' />" # from the detail page
    html += "<br /><br />Product Size-Color Pairing ID (from detail page scraping): <input type='text' name='vendor_scc_value' value='798311' size='40' />" # from javascript of the detail page
    html += "</div>"

    html += '<div style="color: rgb(255, 20, 147);">'
    html += "<br /><br />expected_description: <input type='text' name='expected_description' value='Jones New York Dress, Sleeveless Satin Cowl Neck' size='40' />"
    html += "retailer: <input type='text' name='retailer' value='macys' size='40' />"
    html += "</div>"

    html += "<div>"
    html += "<br /><br />testing (ignore this as a tester): <input type='text' name='testing' value='true' size='40' />"
    html += "<br /><br /><input type='hidden' name='checkout_id' value='rootyroot_fetch_order_data' size='40' />"
    html += "</div>"

    [].each do |field|

      html += "<br /><br />#{field}: <input type='text' name='#{field}' size='100' />"
    end

    html += "<br /><br /><input type='submit' name='Submit' value='Submit' />"
    html += "</form>"

    html
  end

  class SeverityFormatter < Logger::Formatter
    def call(severity, timestamp, progname, msg)
      "#{timestamp} #{severity}: #{msg}\n"
    end
  end

  configure :development do
    require 'ruby-debug'
    require 'fileutils'
    enable :logging, :dump_errors, :raise_errors
    FileUtils.mkdir_p('log')
    set :log, Logger.new('log/checkout-development.log')

    my_logger = Logger.new(File.join('log',"mechanize_development.log"))
    my_logger.formatter = SeverityFormatter.new
    Mechanize.log= my_logger
  end

  configure :staging do
    require 'lib/syslog_logger'
    set :log, SyslogLogger.new('checkout')

    Mechanize.log= log
  end

  configure :production do
    require 'lib/syslog_logger'
    set :log, SyslogLogger.new('checkout')

    Mechanize.log= log
  end

  helpers do

    def extract_checkout_id
      if params[:checkout_id].nil? || params[:checkout_id].empty?
        raise Checkout::CheckoutManager::FatalError.build({:checkout_id => "No checkout id given"}, [])
      end

      params[:checkout_id]
    end

    def manager_class(retailer)
      file = File.join(File.dirname(__FILE__),"managers","#{retailer}.rb")

      require file

      class_name = nil
      File.open(file,"r") do |f|
        f.lines.find{|line| class_name = line.strip[/class\s(.*) </, 1]}
      end

      manager_class = Checkout.const_get(class_name)

      manager_class
    rescue MissingSourceFile => e
      raise Checkout::CheckoutManager::FatalError.build(
                              {Checkout::CheckoutManager::PARAMETER_ERROR_KEY => "Invalid retailer name, could not find that manager"},
                              [],
                              {:parameters_used => retailer})
    rescue NameError => e
      raise Checkout::CheckoutManager::FatalError.build(
                              {Checkout::CheckoutManager::PARAMETER_ERROR_KEY => "Invalid retailer name, must be underscored class name: saksfifthavenue"},
                              [],
                              {:parameters_used => [retailer, manager_class]})
    end

    def run_task(task)
      checkout_id = extract_checkout_id
      start_time = Time.now.to_i
      do_run_task(task).merge({:checkout_id => checkout_id, :seconds_taken => Time.now.to_i - start_time})
    end

    def do_run_task(task)
      sinatra_app_logger = settings.log
      manager_class = manager_class(params[:retailer])
      manager = manager_class.new(params, sinatra_app_logger)
      manager.run(task)

    rescue Checkout::CheckoutManager::FatalError => e
      error_hash = e.to_hash
      sinatra_app_logger.error("#{task} for #{manager_class} failed.\n#{error_hash.inspect}")
      error_hash
    rescue Checkout::CheckoutManager::CheckoutManagerError => e
      e.to_hash
    rescue => e
      sinatra_app_logger.error("#{task} for #{manager_class} failed with unexpected error.\n#{e.message}\n#{e.backtrace}")
      {
        :response_code => Checkout::CheckoutManager::UNKNOWN_ERROR_KEY,
        :errors => {:unknown => "#{e.message}\n#{e.backtrace}"},
      }
    end

    def fetch_detail
      start_time = Time.now.to_i
      do_fetch_detail.merge({:seconds_taken => Time.now.to_i - start_time})
    end

    def do_fetch_detail
      sinatra_app_logger = settings.log
      manager_class = manager_class(params[:retailer])
      manager = manager_class.new(params.merge({:manager_class => manager_class}), sinatra_app_logger)
      manager.fetch_details(params[:product_url], params[:vendor_key])

    rescue Checkout::CheckoutManager::FatalError => e
      error_hash = e.to_hash
      sinatra_app_logger.error("fetch_detail for #{manager_class} failed.\n#{error_hash.inspect}")
      error_hash
    rescue Checkout::CheckoutManager::CheckoutManagerError => e
      e.to_hash
    rescue => e
      sinatra_app_logger.error("#do_fetch_detail for #{manager_class} failed with unexpected error.\n#{e.message}\n#{e.backtrace}")
      {
        :response_code => Checkout::CheckoutManager::UNKNOWN_ERROR_KEY,
        :errors => {:unknown => "#{e.message}\n#{e.backtrace}"},
      }
    end

  end

  run! if app_file == $0

end
