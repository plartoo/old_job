$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'mechanize_extension'

module Checkout
  class RalphLauren < MechanizeCheckoutManager

    HOMEPAGE = "http://www.ralphlauren.com/home/index.jsp"

    COOKIE_FILE_1 = "rootyroot_1.yml"
    COOKIE_FILE_2 = "rootyroot_2.yml"

    CREDIT_CARD_TYPE = {
      "american_express" => "AM",
      "visa" => "VC",
      "master" => "MC",
      "discover" => "DC",
    }

    def do_add_to_bag
      agent_get(:go_to_product, :no_verify => [:page_title])
      scrape_essential_parameters_from_detail_page

      post_and_validate(:add_to_bag, :no_verify => [:page_title, :custom_assert])
      agent_get(:go_to_shopping_bag, :no_verify => [:custom_assert])
      ## cartItemMap, is ESSENTIAL to remove item from bag successfully, could only be seen/scraped after this point
      scrape_cart_item_map_from_shopping_bag_page

      post_and_validate(:go_to_addresses, :no_verify => [:custom_assert])

      cookie_jar.save_as(COOKIE_FILE_1, :yaml) if @testing

      {
        :response_code => SUCCESS_FLAG,
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

      agent_get(:go_to_shopping_bag, :no_verify => [:custom_assert])
      ## scrape cartItemMap, the ESSENTIAL param, to remove item from bag successfully
      cart_item_map = scrape_cart_item_map_from_shopping_bag_page
      post_and_validate(:go_to_addresses, :no_verify => [:page_title, :custom_assert])

      update_flow_trial_number

      ## when retriable error happens, and we resume /fetch_order_data,
      ## we will be brought to a different address page, where we need to 
      ## POST additional post parameters
      if address_book_page?
        scrape_address_id
        post_and_validate(:shipping_and_billing_addresses_retry, :no_verify => [:custom_assert])
      elsif enter_addresses_page?
        post_and_validate(:shipping_and_billing_addresses)
      else
        raise_fatal(
          {:unexpected_page => "expected page title: '#{ADDRESS_BOOK_PAGE_TITLE} or #{GO_TO_ADDRESSES_PAGE_TITLE}'. actual page title: '#{@page.title}'"},
          {:parameters_used => go_to_addresses_parameters}
        )
      end

      update_flow_trial_number
      post_and_validate(:shipping_method, :no_verify => [:custom_assert])

      update_flow_trial_number
      scrape_essential_parameter_from_credit_card_page # to use in POST param for :credit_card
      post_and_validate(:credit_card)

      ## here, we're at the "review order info" page
      update_flow_trial_number

      data = fetch_order_total_data

      cookie_jar.save_as(COOKIE_FILE_2, :yaml) if @testing

      {
        :response_code => SUCCESS_FLAG,
        :retailer_specific_hash => {:checkout_flow_trial_number => @checkout_flow_trial_number}.merge!(cart_item_map),
        :data => data.merge({:cookies => cookie_jar.jar.to_yaml})
      }
    rescue Checkout::CheckoutManager::RetriableError
      raise
    rescue
      remove_item_from_bag
      raise
    end

    def do_purchase
      load_cookies_to_agent

      assert_checkout_flow_number_exists
      post_and_validate(:buy_item, :no_verify => [:custom_assert])
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

    def load_cookies_to_agent
      if @testing
        cookie_jar.load_from_hash(YAML.load_file(COOKIE_FILE_1))
      else
        assert_cookies_exist
        cookie_jar.load_from_hash(YAML.load(@cookies))
      end
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

    def scrape_essential_parameters_from_detail_page
      @cp = @page.search("input[name='cp']").attr('value').value rescue nil
      @pdt_0 = @page.search("input[name='pdt_0']").attr('value').value rescue nil

      grab_parameters_regexp = /pid: ['"](\d+)['"],sku: (\d+),sDesc: ['"]#{@size_name}['"],sId: ['"](\d+)['"],cDesc: ['"]#{@color_name}['"],cId: ['"](\d+)['"],avail: "IN_STOCK/
      match_data = @page.content.match(grab_parameters_regexp)
      @pid = match_data[1] rescue nil
      @sku = match_data[2] rescue nil
      @sid = match_data[3] rescue nil
      @cid = match_data[4] rescue nil

      parameters = {:cp => @cp, :pdt_0 => @pdt_0, :pid => @pid, :sku => @sku, :sid => @sid, :cid => @cid}
      parameters.each do |key, val|
        raise_out_of_stock({:scrape_essential_parameters_from_detail_page => "Failed to scrape some/One of the essential parameters. The item could be out-of-stock."},
                           {:parameters_used => parameters}) if val.nil?
      end
      parameters
    end

    ADD_TO_BAG_URL = "http://www.ralphlauren.com/cartHandler/index.jsp"

    def add_to_bag_parameters
      {
        'action' => 'skuAddToCart',
        'async' => 'true',
        'colors_0' => "#{@pid}|#{@cid}",
        'cp' => "#{@cp}",
        'enh_0' => '',
        'errorMsg' => '0',
        'imageIndex_0' => '0',
        'pdt_0' => "#{@pdt_0}",
        'prodCounter' => '1',
        'prod_0' => "#{@pid}|#{@sku}|#{@sid}",
        'qty_0' => '1',
        'sbsResults' => '',
        'showMy' => '',
        'skuPriceRange_0' => '',
        'thumb_0' => '',
        'wlName' => '',
      }
    end

    ### methods below are used in "/fetch_order_data
    GO_TO_SHOPPING_BAG_URL = "http://www.ralphlauren.com/cart/index.jsp"
    GO_TO_SHOPPING_BAG_PAGE_TITLE = "Your Shopping Bag"

    def scrape_cart_item_map_from_shopping_bag_page
      input_div = @page.search('input').select{|x| x['id'] && x['id'].match(/cartItemMap/i)}
      if input_div.any?
        @cart_item_map = input_div.first.attr('name') rescue nil
      end
      raise_fatal({:scrape_cart_item_map_from_shopping_bag_page =>  "Failed to fetch cart_item_map."}) unless @cart_item_map

      {:cart_item_map => @cart_item_map}
    end

    GO_TO_ADDRESSES_URL = "http://www.ralphlauren.com/cart/shoppingcart.jsp"
    GO_TO_ADDRESSES_PAGE_TITLE = "Enter Address"

    def enter_addresses_page?
      @page.search('title').text.match(/#{GO_TO_ADDRESSES_PAGE_TITLE}/i)
    end

    def go_to_addresses_parameters
      {
        "#{@cart_item_map}" => '1',
        'checkout' => 'Y',
        'ecscheckout' => '',
        'itemNumOnPage' => '',
        'itemRemovedFromCart' => '',
        'moveAllToWishList' => '',
        'moveToWishList' => '',
        'redirectToCartPage' => '',
        'remove' => '',
        'removeFromCart' => '',
        'updateindicator' => '',
      }
    end

    def update_flow_trial_number
      @checkout_flow_trial_number = scrape_checkout_flow_trial_number
    end

    def scrape_checkout_flow_trial_number
      @page.search("input[name='_flowExecutionKey']").attr('value').value rescue nil
    end

    ADDRESS_BOOK_PAGE_TITLE = "Address Book"

    def address_book_page?
      @page.search('title').text.match(/#{ADDRESS_BOOK_PAGE_TITLE}/i)
    end

    def scrape_address_id
      addresses_id_divs = @page.search("input[name='chooseBA']") rescue nil

      # the address on the first row is always our original shipping address
      billing_address_id = addresses_id_divs[0].attr('id') rescue nil
      shipping_address_id = addresses_id_divs[1].attr('id') rescue nil
      @billing_address_id = billing_address_id.match(/(\d+)/)[1] rescue nil
      @shipping_address_id = shipping_address_id.match(/(\d+)/)[1] rescue nil

      if @shipping_address_id.nil? || @billing_address_id.nil?
        raise_fatal({:scrape_address_id => "address_id needed for reposting billing and shipping addresses is not found on Address Book page!"},
                    {:parameters_used => {:shipping_address_id => @shipping_address_id, :billing_address_id => @billing_address_id}})
      end
    end

    SHIPPING_AND_BILLING_ADDRESSES_URL = "https://www.ralphlauren.com/checkout.jsp"
    SHIPPING_AND_BILLING_ADDRESSES_PAGE_TITLE = "SHIPPING METHOD"

    def shipping_and_billing_addresses_parameters
      {
        '_eventId_continue' => 'Continue Checkout',
        '_flowExecutionKey' => "#{@checkout_flow_trial_number}",
        '_sendEmailUpdates' => 'on',
        'billingAddress.address.address1' => @billing_address_1,
        'billingAddress.address.address2' => @billing_address_2,
        'billingAddress.address.address3' => @billing_address_3,
        'billingAddress.address.city' => @billing_city,
        'billingAddress.address.country' => 'US',
        'billingAddress.address.firstName' => @billing_first_name,
        'billingAddress.address.honorific' => '',
        'billingAddress.address.id' => '0',
        'billingAddress.address.lastName' => @billing_last_name,
        'billingAddress.address.postalCode' => @billing_zip,
        'billingAddress.address.state' => @billing_state,
        'billingAddress.address.stateAlternateText' => '',
        'billingAddress.emailAddress' => @email_address,
        'billingAddress.phone' => @billing_phone, ### do not split!!
        'ignoreBillingAddressSuggestions' => 'false',
        'ignoreShippingAddressSuggestions' => 'false',
        'onlyValidateUSandCA' => 'true',
        'sendEmailUpdates' => 'off',
        'shipOption' => '2',
        'shippingAddress.address.address1' => @address_1,
        'shippingAddress.address.address2' => @address_2,
        'shippingAddress.address.address3' => @address_3,
        'shippingAddress.address.city' => @city,
        'shippingAddress.address.country' => 'US',
        'shippingAddress.address.firstName' => @first_name,
        'shippingAddress.address.honorific' => '',
        'shippingAddress.address.id' => '0',
        'shippingAddress.address.lastName' => @last_name,
        'shippingAddress.address.postalCode' => @zip,
        'shippingAddress.address.state' => @state,
        'shippingAddress.address.stateAlternateText' => '',
        'shippingAddress.phone' => @phone, ### do not split!!
        'stateAlternateTextValue' => '',
      }
    end

    def collect_address_errors(error_hash, css_path, prefix="")
      @page.search("#{css_path} p span.error").each do |element|
        msg = element.text.strip + "\n"
        case msg
        when /first name/i
          error_hash["#{prefix}first_name".to_sym] = msg
        when /last name/i
          error_hash["#{prefix}last_name".to_sym] = msg
        when /address/i
          error_hash["#{prefix}address_1".to_sym] = msg
          error_hash["#{prefix}address_2".to_sym] = msg
        when /city/i
          error_hash["#{prefix}city".to_sym] = msg
        when /state/i
          error_hash["#{prefix}state".to_sym] = msg
        when /zip code/i
          error_hash["#{prefix}zip".to_sym] = msg
        when /telephone/i
          error_hash["#{prefix}phone".to_sym] = msg
        when /email/i
          error_hash[:email_address] = msg
        else
          error_hash[:unknown] = 'Unknown field errored.'
        end
      end
      error_hash
    end

    def assert_for_shipping_and_billing_addresses(parameters_used)
      error_hash = {}
      if @page.search('p.error').any?
        error_hash[:main_message] = @page.search('fieldset.address p.error').text.strip + "\n" rescue nil
        collect_address_errors(error_hash, "fieldset.address", "billing_")
        collect_address_errors(error_hash, "fieldset#shipOptFieldset")

        raise_retriable(error_hash, {:parameters_used => parameters_used})
      end
    end

    SHIPPING_AND_BILLING_ADDRESSES_RETRY_URL = "https://www.ralphlauren.com/checkout.jsp"
    SHIPPING_AND_BILLING_ADDRESSES_RETRY_PAGE_TITLE = "SHIPPING METHOD"

    def shipping_and_billing_addresses_retry_parameters
      shipping_and_billing_addresses_parameters.merge({
        "editAddress_#{@shipping_address_id}.address1" => @address_1,
        "editAddress_#{@shipping_address_id}.address2" => @address_2,
        "editAddress_#{@shipping_address_id}.address3" => @address_3,
        "editAddress_#{@shipping_address_id}.address.city" => @city,
        "editAddress_#{@shipping_address_id}.address" => 'US',
        "editAddress_#{@shipping_address_id}.address.firstName" => @first_name,
        "editAddress_#{@shipping_address_id}.address.honorific" => '',
        "editAddress_#{@shipping_address_id}.address.id" => "#{@shipping_address_id}",
        "editAddress_#{@shipping_address_id}.address.lastName" => @last_name,
        "editAddress_#{@shipping_address_id}.address.postalCode" => @zip,
        "editAddress_#{@shipping_address_id}.address.state" => @state,
        "editAddress_#{@shipping_address_id}.address.stateAlternateText" => '',
        "editAddress_#{@shipping_address_id}.phone" => @phone,
        "editAddress_#{@billing_address_id}.address.address1" => @billing_address_1,
        "editAddress_#{@billing_address_id}.address.address2" => @billing_address_2,
        "editAddress_#{@billing_address_id}.address.address3" => @billing_address_3,
        "editAddress_#{@billing_address_id}.address.city" => @billing_city,
        "editAddress_#{@billing_address_id}.address.country" => 'US',
        "editAddress_#{@billing_address_id}.address.firstName" => @billing_first_name,
        "editAddress_#{@billing_address_id}.address.honorific" => '',
        "editAddress_#{@billing_address_id}.address.id" => @billing_address_id,
        "editAddress_#{@billing_address_id}.address.lastName" => @billing_last_name,
        "editAddress_#{@billing_address_id}.address.postalCode" => @billing_zip,
        "editAddress_#{@billing_address_id}.address.state" => @billing_state,
        "editAddress_#{@billing_address_id}.address.stateAlternateText" => '',
        "editAddress_#{@billing_address_id}.phone" => @billing_phone,

        'chooseBA' => '2',
        'shipOpt' => '1',
        'shippingAddress.address.id' => @shipping_address_id,
      })
    end

    SHIPPING_METHOD_URL = "https://www.ralphlauren.com/checkout.jsp"
    SHIPPING_METHOD_PAGE_TITLE = "payment method"

    def shipping_method_parameters
      {
        '_eventId_continue' => '',
        '_flowExecutionKey' => "#{@checkout_flow_trial_number}",
        '_shippingBucketsByAddress[0].shippingBuckets[0].orderItems[0].customerWantsToSeeGiftOptions' => 'on',
        'shippingBucketsByAddress[0].shippingBuckets[0].currentShippingOptionId' => 'Standard_Ground',
      }
    end

    def scrape_essential_parameter_from_credit_card_page
      @billmelater_payment_plan_code = @page.search("input[name='billMeLaterPaymentMethod.selectedPaymentPlanCode']").attr('value').value rescue nil
      raise_fatal({:scrape_essential_parameter_from_credit_card_page =>  "Failed to billmelater_payment_plan_code."}) unless @billmelater_payment_plan_code
    end

    CREDIT_CARD_URL = "https://www.ralphlauren.com/checkout.jsp"
    CREDIT_CARD_PAGE_TITLE = "Review Order Information"

    def credit_card_parameters
      {
        '_eventId_continue' => 'Continue &raquo;',
        '_flowExecutionKey' => "#{@checkout_flow_trial_number}",
        'activePaymentMethod' => 'CREDIT_CARD',

        '_billMeLaterPaymentMethod.agreeToElectronicTAndC' => 'on',
        '_billMeLaterPaymentMethod.agreeToPlanTandC' => 'on',
        'billMeLaterPaymentMethod.dayOfBirth' => 1,
        'billMeLaterPaymentMethod.monthOfBirth' => 1,
        'billMeLaterPaymentMethod.selectedPaymentPlanCode' => "#{@billmelater_payment_plan_code}",
        'billMeLaterPaymentMethod.ssnLast4' => '',
        'billMeLaterPaymentMethod.yearOfBirth' => 1993,

        'creditCardPaymentMethod.cardNumber' => @credit_card_num,
        'creditCardPaymentMethod.cardType' => CREDIT_CARD_TYPE[@credit_card_type.downcase],
        'creditCardPaymentMethod.ccvNumber' => @credit_card_ccv,
        'creditCardPaymentMethod.expirationMonth' => @credit_card_month,
        'creditCardPaymentMethod.expirationYear' => @credit_card_year,
        'creditCardPaymentMethod.selectedCreditCardId' => '',
        'promoCode' => '',
        'redeemableCardPaymentForm.cardNumber' => '',
        'redeemableCardPaymentForm.cardPIN' => '',
      }
    end

    def assert_for_credit_card(parameters_used)
      error_hash = {}
      if @page.search('div.error').any?
        error_hash[:main_message] = @page.search('div.error').map{|x| x.text.strip + "\n"}.join + "\n" rescue nil
        if error_hash[:main_message].match(/credit card/i)
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

    def item_description
      @page.search('td.description p a')[0].text.strip rescue nil
    end

    def fetch_order_total_data
      item_price = page_search_price('fieldset#costSummary table tbody tr td')
      shipping_cost = page_search_price('fieldset#costSummary table tr td.col-bordertop')
      tax = page_search_price('tr.salesTax td')
      order_total = page_search_price('tr.total td')

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
    def assert_checkout_flow_number_exists
      unless @checkout_flow_trial_number
        raise_fatal({:checkout_flow_trial_number => "Checkout flow trial number must be set before calling purchase method!"})
      end
    end

    BUY_ITEM_URL = "https://www.ralphlauren.com/checkout.jsp"
    BUY_ITEM_PAGE_TITLE = "Thank You"

    def buy_item_parameters
      {
        '_eventId_continue' => 'Send Order',
        '_flowExecutionKey' => "#{@checkout_flow_trial_number}",
        'shippingBucketsByAddress[0].shippingBuckets[0].currentShippingOptionId' => 'Standard_Ground',
        'userPrefs' => "TF1;015;;;;;;;;;;;;;;;;;;;;;;Mozilla;Netscape;5.0%20%28X11%3B%20en-US%29;20110422;undefined;true;Linux%20x86_64;true;Linux%20x86_64;undefined;Mozilla/5.0%20%28X11%3B%20U%3B%20Linux%20x86_64%3B%20en-US%3B%20rv%3A1.9.2.17%29%20Gecko/20110422%20Ubuntu/9.10%20%28karmic%29%20Firefox/3.6.17;en-US;undefined;www.ralphlauren.com;undefined;undefined;undefined;undefined;true;true;1311283667446;-8;Tue%2007%20Jun%202005%2009%3A33%3A44%20PM%20PST;1680;1050;;10.2;7.2.0;;;;265;480;420;Thu%2021%20Jul%202011%2002%3A27%3A47%20PM%20PST;24;1680;1000;0;25;;;;;;Shockwave%20Flash%7CShockwave%20Flash%2010.2%20r159;;;;QuickTime%20Plug-in%207.2.0%7CThe%20%3Ca%20href%3D%22http%3A//www.gnome.org/projects/totem/%22%3ETotem%3C/a%3E%202.28.2%20plugin%20handles%20video%20and%20audio%20streams.;;;;;;Windows%20Media%20Player%20Plug-in%2010%20%28compatible%3B%20Totem%29%7CThe%20%3Ca%20href%3D%22http%3A//www.gnome.org/projects/totem/%22%3ETotem%3C/a%3E%202.28.2%20plugin%20handles%20video%20and%20audio%20streams.;;;14;",
      }
    end

    def order_number
      @page.search('div#main-content.checkout-process div.outer-wrap h3 span')[0].text.gsub(/.*?Order.*?: /, '').strip rescue nil
    end

    def order_info_detail
      order_info = @page.search('div.outer-wrap fieldset')[0].to_s rescue ''
      order_cost = @page.search('div.outer-wrap fieldset#costSummary')[0].to_s rescue ''
      order_info + order_cost
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
    REMOVE_FROM_BAG_URL = "http://www.ralphlauren.com/cart/shoppingcart.jsp"

    def remove_item_from_bag
      post_and_validate(:remove_from_bag, :no_verify => [:custom_assert, :page_title])
    end

    def cart_item_id
      raise_fatal({:cart_item_id =>  "cart_item_map is nil."}) unless @cart_item_map
      cart_item_id = @cart_item_map.match(/(\d+)/)[1] rescue nil

      raise_fatal({:cart_item_id =>  "Failed to fetch cart_item_id."}) unless cart_item_id
      cart_item_id
    end

    def remove_from_bag_parameters
      {
        "#{@cart_item_map}" => '1',
        'checkout' => '',
        'ecscheckout' => '',
        'itemNumOnPage' => '',
        'itemRemovedFromCart' => '',
      #  'itemRemovedFromCart' => 'Big Pony Polo Dress',
        'moveAllToWishList' => '',
        'moveToWishList' => '',
        'redirectToCartPage' => '',
        'remove' => cart_item_id,
        'removeFromCart' => 'true',
        'updateindicator' => '',
      }
    end

  end
end


