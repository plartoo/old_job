$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'mechanize_extension'
require 'cgi'

module Checkout
  class Saksfifthavenue < MechanizeCheckoutManager

    HOMEPAGE = "http://www.saksfifthavenue.com"

    COOKIE_FILE_1 = "rootyroot_1.yml"
    COOKIE_FILE_2 = "rootyroot_2.yml"

    CREDIT_CARD_TYPE = {
      "american_express" => "AMEX",
      "visa" => "VISA",
      "master" => "MC",
      "discover" => "DISC",
    }

    def do_add_to_bag
      # we'll do the dirty work in "fetch_order_data" and "purchase"
      {
        :response_code => SUCCESS_FLAG,
        :data => {:cookies => {}.to_yaml},
      }
    rescue
      raise
    end

    def do_fetch_order_data
      ## :go_to_product and "scrape_essential.." are necessary in
      ## do_fetch_order_data and do_purchase because we need to get
      ## checkout session-specific ids from the product page; otherwise, it does NOT work!
      agent_get(:go_to_product, :no_verify => [:page_title])
      scrape_essential_parameters_from_detail_page
      post_and_validate(:add_to_bag, :no_verify => [:page_title, :custom_assert])

      post_and_validate(:initialize_bag_service, :no_verify => [:page_title])
      extract_variable_for_item_removal_from_bag

      post_and_validate(:login_as_guest, :no_verify => [:page_title, :custom_assert])

      post_and_validate(:continue_after_providing_email, :no_verify => [:page_title])

      post_and_validate(:shipping_address_1, :no_verify => [:page_title])
      post_and_validate(:shipping_address_2, :no_verify => [:page_title])

      post_and_validate(:billing_address_1, :no_verify => [:page_title])
      post_and_validate(:billing_address_2, :no_verify => [:page_title])

      post_and_validate(:credit_card, :no_verify => [:page_title])

      assert_description_matches_expected
      data = fetch_order_total_data

      # for Saks, we'll remove the item from bag every time and restart
      # the whole process in buy_item
      remove_item_from_bag

      cookie_jar.save_as(COOKIE_FILE_2, :yaml) if @testing

      {
        :response_code => SUCCESS_FLAG,
        :data => data.merge({:cookies => {}.to_yaml})
      }
    rescue
      remove_item_from_bag
      raise
    end

    def do_purchase
      ## :go_to_product and "scrape_essential.." are necessary in
      ## do_fetch_order_data and do_purchase because we need to get
      ## checkout session-specific ids from the product page; otherwise, it does NOT work!
      agent_get(:go_to_product, :no_verify => [:page_title])
      scrape_essential_parameters_from_detail_page

      post_and_validate(:add_to_bag, :no_verify => [:page_title, :custom_assert])

      post_and_validate(:initialize_bag_service, :no_verify => [:page_title])
      extract_variable_for_item_removal_from_bag

      post_and_validate(:login_as_guest, :no_verify => [:page_title, :custom_assert])

      post_and_validate(:continue_after_providing_email, :no_verify => [:page_title])

      post_and_validate(:shipping_address_1, :no_verify => [:page_title])
      post_and_validate(:shipping_address_2, :no_verify => [:page_title])

      post_and_validate(:billing_address_1, :no_verify => [:page_title])
      post_and_validate(:billing_address_2, :no_verify => [:page_title])

      post_and_validate(:credit_card, :no_verify => [:page_title])
      post_and_validate(:buy_item, :no_verify => [:page_title, :custom_assert])

      fetch_complete_order_information
    rescue Checkout::CheckoutManager::RetriableError
      raise
    rescue
      remove_item_from_bag
      raise
    end

    ############################################################## private methods below ##############################################################
    private
    ### These time limits calls overrides the DEFAULT_TIME_LIMIT definied in mechanize_checkout_manager
    TIME_LIMIT_FOR_DO_FETCH_DETAILS = 5
    TIME_LIMIT_FOR_DO_ADD_TO_BAG = 10
    TIME_LIMIT_FOR_DO_FETCH_ORDER_DATA = 10
    TIME_LIMIT_FOR_DO_PURCHASE = 10
    ###

    ### These are methods always should be defined
    ## ALWAYS define this
    def additional_unloggable_values
      []
    end

    ### methods common to different Saks checkout steps
    def checkout_url
      "https://www.saksfifthavenue.com/checkout/checkout.jsp"
    end

    ### methods below are used in /fetch_order_data
    def go_to_product_url
      @affiliate_url
    end

    def assert_for_go_to_product
      return if @page.is_a?(Mechanize::Page)
      raise_out_of_stock({:url => "Product page is not of type Mechanize::Page, but of class: #{@page.class}"},
                         {:parameters_used => go_to_product_url})
    end

    def scrape_essential_parameters_from_detail_page
      f = @page.form('saks_add_to_cart')
      @product_code = f.send 'ADD_CART_ITEM_ARRAY<>productCode'
      @bm_form_id = f.bmFormID
      @bm_uid = f.bmUID
      @prd_id = f.send 'PRODUCT<>prd_id'

      parameters = {:product_code => @product_code, :bm_form_id => @bm_form_id,
                    :bm_uid => @bm_uid, :prd_id => @prd_id}
      parameters.each do |key, val|
        raise_out_of_stock({:scrape_essential_parameters_from_detail_page => "Failed to scrape some/One of the essential parameters from detail page"},
                           {:parameters_used => parameters}) if val.nil?
      end

      parameters
    end


    ADD_TO_BAG_URL = "http://www.saksfifthavenue.com/main/ProductDetail.jsp"

    def add_to_bag_parameters
      [
        ['ADD_CART_ITEM_ARRAY<>ATR_GiftWrapTypeCode', ''],
        ['ADD_CART_ITEM_ARRAY<>ATR_Returnable', 'TRUE'],
        ['ADD_CART_ITEM_ARRAY<>ATR_giftwrapmessage', ''],
        ['ADD_CART_ITEM_ARRAY<>prd_id', @prd_id],
        ['ADD_CART_ITEM_ARRAY<>productCode', @product_code],
        ['ADD_CART_ITEM_ARRAY<>qtyToBuy', '1'],
        ['ADD_CART_ITEM_ARRAY<>sku_id', @sku_id], # sku_id comes from detail_fetching

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
    end
    # ***

#    GO_TO_BAG_URL = "https://www.saksfifthavenue.com/checkout/SaksBag.jsp"

    # ***
    INITIALIZE_BAG_SERVICE_URL = "https://www.saksfifthavenue.com/checkout/SaksBag.jsp"

    def initialize_bag_service_parameters
      [['bmForm', 'initialize_saks_bag_service']]
    end

    def json_from_cur_page
      JSON.parse(@page.content) rescue {}
    end

    def assert_for_initialize_bag_service
      @json = json_from_cur_page

      if @json['cartItems'].empty?
        raise_out_of_stock({:initialize_bag_service => "The cartItems is empty.  Probably we didn't add this item to bag properly."},
                           {:parameters_used => initialize_bag_service_parameters})
      elsif @json['cartItems'].size > 1
        raise_fatal({:initialize_bag_service => "We added more than one item.  That might be an error because assisted_checkout doesn't allow adding more than one as of August 05, 2011"},
                           {:parameters_used => initialize_bag_service_parameters})
      end
    end
    # ***

    def extract_variable_for_item_removal_from_bag
      @cart_item_id = json_from_cur_page['cartItems'].first['cartItemId']

      unless @cart_item_id
        raise_fatal({:extract_variable_for_item_removal_from_bag => "cartItemId variable, which is necessary for removing item from bag, could not be found"})
      end
    end

    # ***
    LOGIN_AS_GUEST_URL = "https://www.saksfifthavenue.com/checkout/checkout.jsp#init1"

    def email_address
      CGI.escape(@email_address)
    end

    def login_as_guest_parameters
      [
       ["bmForm","login_as_guest_user"],
       ["LOGIN<>userid", email_address],
      ]
    end
    # ***

    # ***
    alias_method :continue_after_providing_email_url, :checkout_url

    def continue_after_providing_email_parameters
      [
        ['bmForm', 'continue_to_checkout_service']
      ]
    end

    def assert_for_continue_after_providing_email
      email = json_from_cur_page['user']['email'] rescue nil

      unless email
        raise_out_of_stock({:assert_for_continue_after_providing_email => "User email address wasn't posted properly."},
                           {:parameters_used => login_as_guest_parameters})
      end
    end
    # ***


    # ***
    alias_method :shipping_address_1_url, :checkout_url

    def shipping_address_common_parameters
      [
        ['SHIP_TO_ADDRESS<>address1', @address_1],
        ['SHIP_TO_ADDRESS<>address2', @address_2],
        ['SHIP_TO_ADDRESS<>address3', @address_3],
        ['SHIP_TO_ADDRESS<>city', @city],

        ['SHIP_TO_ADDRESS<>firstName', @first_name],
        ['SHIP_TO_ADDRESS<>lastName', @last_name],
        ['SHIP_TO_ADDRESS<>middleName', ''],
        ['SHIP_TO_ADDRESS<>state_cd', @state],
        ['SHIP_TO_ADDRESS<>postal', @zip],
        ['SHIP_TO_ADDRESS<>phone',	@phone],
        ['count', '1'],

        ['shiptomult', 'false'],
        ['setAsBillAddress', 'false'],
        ['SHIP_TO_ADDRESS<>uad_id', ''],
        ['SHIP_TO_ADDRESS<>indGift', '0'],
      ]
    end

    def shipping_address_1_parameters
      shipping_address_common_parameters << ['bmForm', 'validate_ship_address_service']
    end

    def assert_address(parameters)
      error_hash = {}
      if json_from_cur_page['errors'] && json_from_cur_page['errors'].any?
        msg = json_from_cur_page['errors'].first['message']
        error_hash[:main_message] = msg

        
        error_hash[:first_name] = msg if msg.match(/first name/i)
        error_hash[:last_name] = msg if msg.match(/last name/i)
        error_hash[:city] = msg if msg.match(/city/i)
        error_hash[:state] = msg if msg.match(/state/i)
        error_hash[:zip] = msg if msg.match(/zip code/i)
        error_hash[:phone] = msg if msg.match(/phone/i)

        if msg.match(/address/i)
          error_hash[:address_1] = msg
          error_hash[:address_2] = msg
        end

        if error_hash.size == 1 # meaning there's only :main_message in error_hash
          error_hash[:unknown] = 'Unknown field errored.'
        end

        raise_retriable(error_hash, {:parameters_used => parameters})
      end
    end

    def assert_for_shipping_address_1
      assert_address(shipping_address_1_parameters)
    end
    # ***

    # ***
    alias_method :shipping_address_2_url, :checkout_url

    def shipping_address_2_parameters
      shipping_address_common_parameters << ['bmForm', 'add_address_and_continue_service']
    end

    def assert_for_cart_items(parameters)
      hash = json_from_cur_page['orderItems'].first['cartItem'] rescue nil
      unless hash
        raise_fatal({:assert_for_cart_items => "The return hash doesn't have value for cartItems key"},
                    {:parameters_used => parameters})
      end
    end

    def assert_for_shipping_address_2
      assert_for_cart_items(shipping_address_2_parameters)
    end
    # ***

    # ***
    alias_method :billing_address_1_url, :checkout_url

    def billing_address_common_parameters
      [
        ['BILL_TO_ADDRESS<>address1', @billing_address_1],
        ['BILL_TO_ADDRESS<>address2', @billing_address_2],
        ['BILL_TO_ADDRESS<>address3', @billing_address_3],
        ['BILL_TO_ADDRESS<>city', @billing_city],

        ['BILL_TO_ADDRESS<>firstName', @billing_first_name],
        ['BILL_TO_ADDRESS<>middleName', ''],
        ['BILL_TO_ADDRESS<>lastName', @billing_last_name],
        ['BILL_TO_ADDRESS<>phone', @billing_phone],
        ['BILL_TO_ADDRESS<>postal', @billing_zip],
        ['BILL_TO_ADDRESS<>stateName', ''],
        ['BILL_TO_ADDRESS<>state_cd', @billing_state],
        ['BILL_TO_ADDRESS<>country_cd', 'US'],


        ['BILL_TO_ADDRESS<>indDefaultBillTo', 'false'],
        ['BILL_TO_ADDRESS<>indGift', '0'],
        ['BILL_TO_ADDRESS<>uad_id', ''],
        ['setAsShipAddress', 'false'],
      ]
    end

    def billing_address_1_parameters
      billing_address_common_parameters << ['bmForm', 'validate_bill_address_service']
    end

    def assert_for_billing_address_1
      assert_address(billing_address_1_parameters)
    end
    # ***

    # ***
    alias_method :billing_address_2_url, :checkout_url

    def billing_address_2_parameters
      billing_address_common_parameters << ['bmForm', 'save_billing_address_service']
    end

    def assert_for_billing_address_2
      assert_for_cart_items(billing_address_2_parameters)
    end
    # ***

    # ***
    alias_method :credit_card_url, :checkout_url

    def credit_card_type
      CREDIT_CARD_TYPE[@credit_card_type.downcase]
    end

    def credit_card_holder_name
      "#{@billing_first_name} #{@billing_last_name}"
    end

    def credit_card_parameters
      [
        ['bmForm', 'submit_payment_service'],
        ['ACCOUNT<>accountNumber', ''],
        ['ACCOUNT<>notificationEmail', ''],
        ['CREDIT_CARD<>cardholderName', credit_card_holder_name],
        ['CREDIT_CARD<>cardBrand_cd', credit_card_type],
        ['CREDIT_CARD<>cardNum', @credit_card_num],
        ['CREDIT_CARD<>cardMonth_cd', @credit_card_month],
        ['CREDIT_CARD<>cardYear_cd', @credit_card_year],
        ['card_cvNumber', @credit_card_ccv],
        ['USER_ACCOUNT<>ATR_passwordHint', ''],
        ['USER_ACCOUNT<>confirmPassword', ''],
        ['USER_ACCOUNT<>password', ''],
        ['promoCode', ''],
      ]
    end

    def credit_card_error_check(parameters)
      error_hash = {}
      if json_from_cur_page['errors'] && json_from_cur_page['errors'].any?
        error_hash[:main_message] = json_from_cur_page['errors'].first['message']

        if error_hash[:main_message].match(/credit card/i)
          error_hash[:generic_credit_card] = error_hash[:main_message]
          error_hash[:credit_card_type] = error_hash[:main_message]
          error_hash[:credit_card_num] = error_hash[:main_message]
          error_hash[:credit_card_month] = error_hash[:main_message]
          error_hash[:credit_card_year] = error_hash[:main_message]
          error_hash[:credit_card_ccv] = error_hash[:main_message]
        end

        raise_retriable(error_hash, {:parameters_used => parameters})
      end
    end

    def assert_for_credit_card
      credit_card_error_check(credit_card_parameters)
    end
    # ***

    # ***
    def item_description
      cart_item = json_from_cur_page['orderItems'].first['cartItem'] rescue {}
      cart_item['shortDescription']
    end

    def assert_description_matches_expected
      desc = CheckoutUtils.extract_alphabets_only(item_description)
      expected_desc = CheckoutUtils.extract_alphabets_only(@expected_description)
      errors = errors_for_unexpected(desc, expected_desc, "expected_description")
      raise_fatal(errors) if errors.any?
    end

    def clean_html_entity(hash)
      hash.each do |k,v|
        hash[k] = v.gsub(/^\s?&#36;/,'') # clean html entities in the BEGINNING of the word " &#36;xx.xx"
      end

      hash
    end

    def fetch_order_total_data
      order_summary = clean_html_entity(json_from_cur_page['orderSummary'])

      item_price = CheckoutUtils.price_str_to_decimal(order_summary['itemsTotal']) rescue nil
      shipping_cost = CheckoutUtils.price_str_to_decimal(order_summary['shippingCost']) rescue nil
      tax = CheckoutUtils.price_str_to_decimal(order_summary['tax']) rescue nil
      order_total = CheckoutUtils.price_str_to_decimal(order_summary['creditCardTotal']) rescue nil

      data = {
        :item_price => item_price,
        :shipping_cost => shipping_cost,
        :tax => tax,
        :order_total => order_total,
      }
      assert_critical_order_info_is_not_nil([:item_price, :shipping_cost, :tax, :order_total], data)

      discount = calculate_discount(order_total, [item_price, shipping_cost, tax])

      data.merge({:discount => discount})
    end
    # ***

    alias_method :buy_item_url, :checkout_url

    def buy_item_parameters
      [
        ['bmForm', 'submit_order_service'],
      ]
    end

    def assert_for_buy_item
      credit_card_error_check(buy_item_parameters)
    end

    def order_number
      json_from_cur_page['orderNumber'] rescue nil
    end

    def fetch_complete_order_information
      data = {:order_number => order_number}
      assert_critical_order_info_is_not_nil([:order_number], data)

      {
        :response_code => SUCCESS_FLAG,
        :data => data.merge({:order_info_detail => json_from_cur_page})
      }
    end

    ### Methods called when removing item from shopping bag
    alias_method :remove_from_bag_url, :checkout_url

    def remove_item_from_bag
      post_and_validate(:remove_from_bag, :no_verify => [:custom_assert, :page_title])
    end

    def remove_from_bag_parameters
      {
        "bmForm" => 'remove_cart_item_service',
        'cartItemId' => @cart_item_id,
      }
    end

  end
end


