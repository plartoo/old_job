$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'mechanize_extension'

module Checkout
  class Bluefly < MechanizeCheckoutManager

    HOMEPAGE = "http://www.bluefly.com"

    COOKIE_FILE_1 = "rootyroot_1.yml"
    COOKIE_FILE_2 = "rootyroot_2.yml"

    CREDIT_CARD_TYPE = {
      "american_express" => "AM",
      "visa" => "VC",
      "master" => "MC",
      "discover" => "DC",
    }

    def do_add_to_bag
      assert_variable_exists(@catalog_ref_id, "catalog_ref_id must exists!")
      agent_get(:go_to_product, :no_verify => [:page_title])

      post_and_validate(:add_to_bag, :no_verify => [:page_title, :custom_assert])
      update_dynamic_session_number
      scrape_variable_for_remove_bag

      agent_get(:go_to_shopping_bag, :no_verify => [:custom_assert])
      update_dynamic_session_number

      post_and_validate(:go_to_login, :no_verify => [:custom_assert])

      update_dynamic_session_number

      agent_get(:go_to_shipping, :no_verify => [:custom_assert])
      update_dynamic_session_number

      cookie_jar.save_as(COOKIE_FILE_1, :yaml) if @testing

      {
        :response_code => SUCCESS_FLAG,
        :retailer_specific_hash => {:dyn_sess_conf => @dyn_sess_conf, :remove_id_1 => @remove_id_1},
        :data => {:cookies => cookie_jar.jar.to_yaml},
      }
    rescue Checkout::CheckoutManager::RetriableError
      raise
    rescue
      remove_item_from_bag
      raise
    end

    def do_fetch_order_data
      load_cookies_to_agent
      assert_variable_exists(@dyn_sess_conf, "dyn_sess_conf must exists!")
      assert_variable_exists(@remove_id_1, "remove_id_1 must exists!")

      agent_get(:go_to_shopping_bag, :no_verify => [:custom_assert])
      update_dynamic_session_number

      post_and_validate(:go_to_login, :no_verify => [:custom_assert, :page_title])
      update_dynamic_session_number

      if log_in_page?
        agent_get(:go_to_shipping, :no_verify => [:custom_assert])
        update_dynamic_session_number
        post_and_validate(:go_to_billing, :no_verify => [:custom_assert]) # we cannot verify form errors without javascript.  Jeremy says SITM front end will handle this
      elsif confirmation_page? # that means, we're retrying after some sort of retriable failure; I'll assume this is due to credit card error here
        agent_get(:go_to_payment_information, :no_verify => [:custom_assert])
      else
        raise_fatal(
          {:unexpected_page => "expected page title: '#{GO_TO_REVIEW_PAGE_TITLE} or #{GO_TO_BILLING_PAGE_TITLE}'. actual page title: '#{@page.title}'"},
          {:parameters_used => go_to_billing_parameters}
        )
      end

      update_dynamic_session_number

      post_and_validate(:go_to_review, :no_verify => [:custom_assert]) # we cannot verify form errors without javascript.  Jeremy says SITM front end will handle this
      update_dynamic_session_number

      assert_description_matches_expected
      data = fetch_order_total_data

      cookie_jar.save_as(COOKIE_FILE_2, :yaml) if @testing

      {
        :response_code => SUCCESS_FLAG,
        :retailer_specific_hash => {:dyn_sess_conf => @dyn_sess_conf, :remove_id_1 => @remove_id_1},
        :data => data.merge({:cookies => cookie_jar.jar.to_yaml})
      }
    rescue Checkout::CheckoutManager::RetriableError
      raise
    rescue => e
      remove_item_from_bag
      raise
    end

    def do_purchase
      load_cookies_to_agent
      assert_variable_exists(@dyn_sess_conf, "dyn_sess_conf must exists!")
      assert_variable_exists(@remove_id_1, "remove_id_1 must exists!")

      # credit card error will happen here, so we will use assert_... to check
      # if we are sent back to billing page (instead of checking Thank you page
      # title, which will be done manually)
      post_and_validate(:buy_item, :no_verify => [:page_title])
      assert_on_page(BUY_ITEM_PAGE_TITLE, buy_item_parameters)

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
    TIME_LIMIT_FOR_DO_ADD_TO_BAG = 15
    TIME_LIMIT_FOR_DO_FETCH_ORDER_DATA = 15
    TIME_LIMIT_FOR_DO_PURCHASE = 15
    ###

    ### These are methods always should be defined
    ## ALWAYS define this
    def additional_unloggable_values
      []
    end

    def load_cookies_to_agent
      if @testing
        cookie_jar.load_from_hash(YAML.load_file(COOKIE_FILE_1))
      else
        assert_cookies_exist
        cookie_jar.load_from_hash(YAML.load(@cookies))
      end
    end

    ### These are specific to Bluefly and are used by every method in Bluefly checkout

    # Bluefly only holds an item in the bag for 30mins
    def assert_if_we_are_told_to_restart_checkout
      if @page.search('div#checkoutNoSession').any?
        msg = @page.search('div#checkoutNoSession').text.strip + "\n" rescue ''
        if msg.match(/go back.*?shopping bag/i)
          raise_retriable({:assert_if_we_are_told_to_restart_checkout => "#{msg}"})
        end
      end
    end

    def after_post
      assert_if_we_are_told_to_restart_checkout
    end

    def create_param_hash(keys)
      parameters = {}
      keys.each do |key|
        css_path = "input[name='#{key}']"
        val = @page.search(css_path).first.attr('value') rescue nil
        parameters[key] = val
      end

      parameters
    end

    ### methods below are used in "/add_to_bag
    def go_to_product_url
      @affiliate_url
    end

    def assert_for_go_to_product
      return if @page.is_a?(Mechanize::Page)
      raise_out_of_stock({:url => "Product page is not of type Mechanize::Page, but of class: #{@page.class}"},
                         {:parameters_used => go_to_product_url})
    end


    ADD_TO_BAG_URL = "http://www.bluefly.com/browse/product_detail.jsp?_DARGS=/browse/f_product_detail.jsp"

    def add_to_bag_parameters
      params = create_param_hash([
          '/atg/b2cblueprint/order/purchase/CartFormHandler.addItemCount',
          '/atg/b2cblueprint/order/purchase/CartFormHandler.addItemToOrder',
          '/atg/b2cblueprint/order/purchase/CartFormHandler.addItemToOrderErrorURL',
          '/atg/b2cblueprint/order/purchase/CartFormHandler.addItemToOrderSuccessURL',
          '/atg/b2cblueprint/order/purchase/CartFormHandler.analyticsCatId',
          '/atg/b2cblueprint/order/purchase/CartFormHandler.items[0].productId',
          '_D:/atg/b2cblueprint/order/purchase/CartFormHandler.addItemCount',
          '_D:/atg/b2cblueprint/order/purchase/CartFormHandler.addItemToOrder',
          '_D:/atg/b2cblueprint/order/purchase/CartFormHandler.addItemToOrderErrorURL',
          '_D:/atg/b2cblueprint/order/purchase/CartFormHandler.addItemToOrderSuccessURL',
          '_D:/atg/b2cblueprint/order/purchase/CartFormHandler.analyticsCatId',
          '_D:/atg/b2cblueprint/order/purchase/CartFormHandler.catalogRefId',
          '_D:/atg/b2cblueprint/order/purchase/CartFormHandler.items[0].productId',
          '_D:addQuantity',
          '_DARGS',
          '_dynSessConf',
          '_dyncharset',
          'addQuantity',
          'ajaxCall',])

      params['/atg/b2cblueprint/order/purchase/CartFormHandler.catalogRefId'] = @catalog_ref_id

      params
    end

    def scrape_variable_for_remove_bag
      @remove_id_1 = @page.search("input[name='/atg/b2cblueprint/order/purchase/CartFormHandler.giftWrapSelecteds']").first.attr('value') rescue nil
      if @remove_id_1.nil?
        raise_fatal({:scrape_variables_for_remove_bag => "parameters needed for removing item from bag could not be found!"},
                    {:parameters_used => {:remove_id_1 => @remove_id_1, :dyn_sess_conf => @dyn_sess_conf}})
      end
    end

    ### methods below are used in "/fetch_order_data
    GO_TO_SHOPPING_BAG_URL = "http://www.bluefly.com/cart/cart.jsp"
    GO_TO_SHOPPING_BAG_PAGE_TITLE = "Shopping Bag"


    GO_TO_LOGIN_URL = "http://www.bluefly.com/cart/cart.jsp?_DARGS=/cart/cart_contents.jsp.checkout"
    GO_TO_LOGIN_PAGE_TITLE = "Login"

    def log_in_page?
      @page.title.match(/#{GO_TO_LOGIN_PAGE_TITLE}/i)
    end

    def go_to_login_parameters
      params = create_param_hash([
          '/atg/b2cblueprint/order/purchase/CartFormHandler.moveToPurchaseInfoSuccessURL',
          '/atg/b2cblueprint/order/purchase/CartFormHandler.purchaseInfoSuccessConfirmURL',
          '_D:/atg/b2cblueprint/order/purchase/CartFormHandler.checkout',
          '_D:/atg/b2cblueprint/order/purchase/CartFormHandler.moveToPurchaseInfoSuccessURL',
          '_D:/atg/b2cblueprint/order/purchase/CartFormHandler.purchaseInfoSuccessConfirmURL',
          '_DARGS',
          '_dynSessConf',
          '_dyncharset',
        ])

      params['/atg/b2cblueprint/order/purchase/CartFormHandler.checkout.x'] = 65
      params['/atg/b2cblueprint/order/purchase/CartFormHandler.checkout.y'] = 28

      key = @page.search("input[name='/atg/b2cblueprint/order/purchase/CartFormHandler.giftWrapSelecteds']").first.attr('value') rescue nil
      params[key] = 1 if key

      params
    end

    def scrape_dynamic_session_number
      @page.search("input[name='_dynSessConf']").attr('value').value rescue nil
    end

    def update_dynamic_session_number
      @dyn_sess_conf = scrape_dynamic_session_number
    end


    GO_TO_SHIPPING_PAGE_TITLE = "Shipping Information"

    def go_to_shipping_url
      "http://www.bluefly.com/checkout/login.jsp?_dyncharset=UTF-8&_dynSessConf=#{@dyn_sess_conf}&/atg/userprofiling/B2CProfileFormHandler.loginSuccessURL=/checkout/shipping.jsp&_D:/atg/userprofiling/B2CProfileFormHandler.loginSuccessURL=+&checkoutLoginOption=continueanonymous&_D:checkoutLoginOption=+&/atg/userprofiling/B2CProfileFormHandler.loginDuringCheckout.x=90&/atg/userprofiling/B2CProfileFormHandler.loginDuringCheckout.y=20&_D:/atg/userprofiling/B2CProfileFormHandler.loginDuringCheckout=+&_DARGS=/checkout/login_form.jsp.checkoutGuest"
    end


    GO_TO_BILLING_URL = "http://www.bluefly.com/checkout/shipping.jsp?_DARGS=/checkout/shipping_form.jsp"
    GO_TO_BILLING_PAGE_TITLE = "Billing Information"

    def go_to_billing_parameters
      params = create_param_hash([
          '_D:addressLine2',
          '_D:city',
          '_D:comments',
          '_D:company',
          '_D:continue',
          '_D:country',
          '_D:firstname',
          '_D:giftCheck',
          '_D:lastname',
          '_D:nickname',
          '_D:phone',
          '_D:phone',
          '_D:shipmethod',
          '_D:shipmethod',
          '_D:shipmethod',
          '_D:shipmethod',
          '_D:shipmethod',
          '_D:shipmethod',
          '_D:state',
          '_D:state',
          '_D:state',
          '_D:streetAddress',
          '_D:useAddress',
          '_D:zipCode',
          '_D:zipCode',
          '_D:zipCode',
          '_DARGS',
          '_dynSessConf',
          '_dyncharset',
        ])

      params['continue.x'] = 54
      params['continue.y'] = 54

      params['firstname'] = @first_name
      params['lastname'] = @last_name
      params['nickname'] = @nick_name
      params['company'] = @company
      params['streetAddress'] = @address_1
      params['addressLine2'] = @address_2
      params['city'] = @city
      params['state'] = @state
      params['zipCode'] = @zip
      params['phone'] = split_phone_number_in_three(@phone).join
      params['shipmethod'] = 'Standard'
      params['country'] = 'US'

      params
    end

    GO_TO_PAYMENT_INFORMATION_URL = "http://www.bluefly.com/checkout/billing.jsp?edit=true"
    GO_TO_PAYMENT_INFORMATION_PAGE_TITLE = "Billing Information"


    GO_TO_REVIEW_URL = "https://www.bluefly.com/checkout/billing.jsp?_DARGS=/checkout/billing_form.jsp"
    GO_TO_REVIEW_PAGE_TITLE = "Confirmation"

    def confirmation_page?
      @page.title.match(/#{GO_TO_REVIEW_PAGE_TITLE}/i)
    end

    def go_to_review_parameters
      params = create_param_hash([
          '/atg/commerce/order/purchase/PaymentGroupFormHandler.creditCardMap.creditCardType',
          '/atg/commerce/order/purchase/PaymentGroupFormHandler.guestCheckout',
          '_D:/atg/commerce/order/purchase/PaymentGroupFormHandler.creditCardMap.creditCardType',
          '_D:/atg/commerce/order/purchase/PaymentGroupFormHandler.guestCheckout',
          '_D:/atg/commerce/order/purchase/PaymentGroupFormHandler.moveToConfirm',
          '_D:addressLine2Bill',
          '_D:billState',
          '_D:billState',
          '_D:billState',
          '_D:cardNo',
          '_D:cemail',
          '_D:cityBill',
          '_D:companyBill',
          '_D:countryBill',
          '_D:emailConfirm',
          '_D:expirationMo',
          '_D:expirationYr',
          '_D:firstnameBill',
          '_D:lastnameBill',
          '_D:nameOnCard',
          '_D:paymentType',
          '_D:paymentType',
          '_D:phoneBill',
          '_D:streetAddressBill',
          '_D:useAddress',
          '_D:zipCodeBill',
          '_DARGS',
          '_dynSessConf',
          '_dyncharset',
        ])

      params['paymentType'] = 'creditcard'
      params['/atg/commerce/order/purchase/PaymentGroupFormHandler.moveToConfirm.x'] = 39
      params['/atg/commerce/order/purchase/PaymentGroupFormHandler.moveToConfirm.y'] = 9

      params['cardNo'] = @credit_card_num
      params['expirationMo'] = @credit_card_month
      params['expirationYr'] = @credit_card_year

      params['firstnameBill'] = @billing_first_name
      params['lastnameBill'] = @billing_last_name
      params['nameOnCard'] = "#{@billing_first_name} #{@billing_last_name}"

      params['companyBill'] = @company_bill

      params['streetAddressBill'] = @billing_address_1
      params['addressLine2Bill'] = @billing_address_2
      params['cityBill'] = @billing_city
      params['billState'] = @billing_state
      params['zipCodeBill'] = @billing_zip.to_i
      params['countryBill'] = 'US'
      params['phoneBill'] = split_phone_number_in_three(@billing_phone).join
      params['cemail'] = @email_address
      params['emailConfirm'] = @email_address

      params
    end

    def assert_for_go_to_review(parameters_used)
      # to check if we're being re-directed to billing page
      error_hash = {}
      error_msg = @page.search('div.errColumn').text.strip rescue ''
      if error_msg.any?
        error_hash[:main_message] = error_msg + "\n" rescue nil

        @page.search('div.errColumn div.invalidMarker').each do |element|
          msg = element.text.strip + "\n"
          case msg
          when /card number/i
            error_hash[:credit_card_num] = msg
          when /security code/i
            error_hash[:credit_card_ccv] = msg
          when /expiration date/i
            error_hash[:credit_card_month] = msg
            error_hash[:credit_card_year] = msg
          when /first name/i
            error_hash[:billing_first_name] = msg
          when /last name/i
            error_hash[:billing_last_name] = msg
          when /address/i
            error_hash[:billing_address_1] = msg
            error_hash[:billing_address_2] = msg
          when /city/i
            error_hash[:billing_city] = msg
          when /state/i
            error_hash[:billing_state] = msg
          when /postal code/i
            error_hash[:billing_zip] = msg
          when /phone/i
            error_hash[:billing_phone] = msg
          when /email/i
            error_hash[:email_address] = msg
          else
            error_hash[:unknown] = 'Unknown field errored.'
          end
        end
        raise_retriable(error_hash, {:parameters_used => parameters_used})
      end
    end

    def item_description
      @page.search('a.checkoutShortName')[0].text.strip rescue nil
    end

    def assert_description_matches_expected
      desc = CheckoutUtils.extract_alphabets_only(item_description)
      expected_desc = CheckoutUtils.extract_alphabets_only(@expected_description)
      errors = errors_for_unexpected(desc, expected_desc, "expected_description")
      raise_fatal(errors) if errors.any?
    end

    def page_search_price(css_selector)
      str = @page.search(css_selector).text.strip rescue nil
      CheckoutUtils.price_str_to_decimal(str)
    end

    def fetch_order_total_data
      item_price = page_search_price('td.checkoutTextSubTotal')
      shipping_cost = page_search_price('td.checkoutTextShipping')
      tax = page_search_price('td.checkoutTextTax')
      order_total = page_search_price('td.checkoutTextTotal')

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


    ### methods below are used in "/purchase
    BUY_ITEM_URL = "https://www.bluefly.com/checkout/confirm.jsp?_DARGS=/checkout/confirm_form.jsp.checkoutConfirmForm"
    BUY_ITEM_PAGE_TITLE = "Thank You"

    def buy_item_parameters
      params = {
        '/bluefly/commerce/order/purchase/CommitOrderFormHandler.commitOrder.x' => 23,
        '/bluefly/commerce/order/purchase/CommitOrderFormHandler.commitOrder.y' => 17,
        '/bluefly/commerce/order/purchase/CommitOrderFormHandler.commitOrderErrorURL' => 'billing.jsp?edit=true',
        '/bluefly/commerce/order/purchase/CommitOrderFormHandler.commitOrderErrorURL' => 'billing.jsp?edit=true',
        '/bluefly/commerce/order/purchase/CommitOrderFormHandler.commitOrderSuccessURL' => 'thankyou.jsp',
        '_D:/bluefly/commerce/order/purchase/CommitOrderFormHandler.commitOrder' => '',
        '_D:/bluefly/commerce/order/purchase/CommitOrderFormHandler.commitOrder' => '',
        '_D:/bluefly/commerce/order/purchase/CommitOrderFormHandler.commitOrderErrorURL' => '',
        '_D:/bluefly/commerce/order/purchase/CommitOrderFormHandler.commitOrderErrorURL' => '',
        '_D:/bluefly/commerce/order/purchase/CommitOrderFormHandler.commitOrderSuccessURL' => '',
        '_DARGS' => '/checkout/confirm_form.jsp.checkoutConfirmForm',
        '_dyncharset' => 'ISO-8859-1',
        '_dynSessConf' => @dyn_sess_conf,
      }

      params
    end

    def assert_for_buy_item(parameters_used)
      # to check if we're being re-directed to billing page
      error_hash = {}
      error_msg = @page.search('div.errColumn').text.strip rescue ''
      if error_msg.match(/error placing the order/i)
        error_hash[:main_message] = error_msg + "\n" rescue nil
        if error_hash[:main_message].match(/ensure that the billing information/i)
          error_hash[:generic_credit_card] = error_hash[:main_message]
          error_hash[:credit_card_type] = error_hash[:main_message]
          error_hash[:credit_card_num] = error_hash[:main_message]
          error_hash[:credit_card_month] = error_hash[:main_message]
          error_hash[:credit_card_year] = error_hash[:main_message]
          error_hash[:credit_card_ccv] = error_hash[:main_message]
        end
        raise_retriable(error_hash, {:parameters_used => parameters_used})
      end
    end

    def order_number
      @page.search('p#printOrderLink').text.match(/order.*?(\d+)/i)[1] rescue nil
    end

    def order_info_detail
      order_info = @page.search('div#checkoutMainColumn').to_s rescue ''
    end

    def fetch_complete_order_information
      data = {:order_number => order_number}
      assert_critical_order_info_is_not_nil([:order_number], data)
      {
        :response_code => SUCCESS_FLAG,
        :data => data.merge({:order_info_detail => order_info_detail})
      }
    end

    ### Methods called when removing item from shopping bag
    def remove_from_bag_url
      "http://www.bluefly.com/cart/cart.jsp?_DARGS=/cart/cart_item.jsp_A&_DAV=#{@remove_id_1}&_dynSessConf=#{@dyn_sess_conf}"
    end

    def remove_item_from_bag
      agent_get(:remove_from_bag, :no_verify => [:custom_assert, :page_title])
    end

  end
end


