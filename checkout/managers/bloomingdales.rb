$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'mechanize_extension'

module Checkout
  class Bloomingdales < MechanizeCheckoutManager

    HOMEPAGE = "http://www.bloomingdales.com"

    CHECKOUT_FLOW_URL = "https://www.bloomingdales.com/checkoutswf/checkout-webflow?execution="

    BILLING_PAGE_TITLE = "Shopping Bag - Billing Information"

    COOKIE_FILE_1 = "rootyroot_1.yml"
    COOKIE_FILE_2 = "rootyroot_2.yml"

    CREDIT_CARD_TYPE = {
      "american_express" => "A",
      "visa" => "V",
      "master" => "M",
      "discover" => "O",

      "bloomingdale's" => "U",
      "bloomingdale's american express" => "B",
      "bloomingdale's visa" => "X",
      "bloomingdale's employee card" => "F",
    }

    def do_add_to_bag
      extract_product_id

      agent_get(:go_to_product, :no_verify => [:page_title])
      post_and_validate(:add_to_bag, :no_verify => [:page_title])
      agent_get(:go_to_shopping_bag, {:headers => cookie_header, :no_verify => [:custom_assert]})
      post_and_validate(:go_to_profile_creation, :no_verify => [:custom_assert])
      post_and_validate(:go_to_shipping_info, :no_verify => [:custom_assert])

      cookie_jar.save_as(COOKIE_FILE_1, :yaml) if @testing

      {
        :response_code => SUCCESS_FLAG,
        :data => {:cookies => cookie_jar.jar.to_yaml}
      }
    rescue Checkout::CheckoutManager::RetriableError
      raise
    rescue
      remove_item_from_bag
      raise
    end

    def do_fetch_order_data
      extract_product_id
      load_cookies_to_agent

      agent_get(:go_to_shopping_bag, {:headers => cookie_header, :no_verify => [:custom_assert]})
      post_and_validate(:skip_profile_creation_and_go_to_shipping_info, :no_verify => [:custom_assert])
      fill_out_shipping_address_info_and_proceed
      update_flow_trial_number
      post_and_validate(:billing_address)
      assert_description_matches_expected

      data = fetch_order_total_data

      update_flow_trial_number

      cookie_jar.save_as(COOKIE_FILE_2, :yaml) if @testing

      {
        :response_code => SUCCESS_FLAG,
        :retailer_specific_hash => {:checkout_flow_trial_number => @checkout_flow_trial_number},
        :data => data.merge({:cookies => cookie_jar.jar.to_yaml})
      }
    rescue Checkout::CheckoutManager::RetriableError
      raise
    rescue
      remove_item_from_bag
      raise
    end

    def do_purchase
      if @testing
        @checkout_flow_trial_number = 'e2s4'
      end
      load_cookies_to_agent

      assert_checkout_flow_number_exists
      post_and_validate(:buy_item)
      fetch_complete_order_information
    rescue Checkout::CheckoutManager::RetriableError
      raise
    rescue
      remove_item_from_bag
      raise
    end

    ############################################################## private methods below ##############################################################
    private

    GO_TO_SHOPPING_BAG_URL = "http://www1.bloomingdales.com/bag/index.ognc"
    GO_TO_SHOPPING_BAG_PAGE_TITLE = "Bloomingdales.com - Shopping Bag"

    ### These time limits calls overrides the DEFAULT_TIME_LIMIT definied in mechanize_checkout_manager
    TIME_LIMIT_FOR_DO_FETCH_DETAILS = 5
    TIME_LIMIT_FOR_DO_ADD_TO_BAG = 10
    TIME_LIMIT_FOR_DO_FETCH_ORDER_DATA = 10
    TIME_LIMIT_FOR_DO_PURCHASE = 10
    ###

    def cookie_header
      {"Cookie" => cookie_string(['JSESSIONID', 'HISTORY_KEY', 'GCs'])}
    end

    def extract_product_id
      @id = @url.match(/\?ID=(\d+)/)[1]
    rescue
      raise_fatal({:extract_product_id => "Something went wrong in extracting product id from product_url"},
                  {:parameters_used => @url})
    end
    
    def assert_currently_unavailable_error
      if @page.search('div.ch_errorMsg').any?
        msg = @page.search('div.ch_errorMsg').text.strip + "\n" rescue ''
        if msg.match(/unavailable/i)
          raise_out_of_stock({:shipping_address => "The item may be out of stock. We got this message: #{msg}"})
        end
      end
    end

    def after_post
      assert_currently_unavailable_error
    end

    def shipping_method_option_exists?
      @page.search('div#globalContentContainer div.ch_shippingOptionsContainer form').any?
    end

    def fill_out_shipping_address_info_and_proceed
      update_flow_trial_number
      post_and_validate(:shipping_address, :no_verify => [:page_title])

      if shipping_method_option_exists?
        select_shipping_option_and_proceed
      end
      assert_on_page(BILLING_PAGE_TITLE, shipping_address_parameters)
    end

    def select_shipping_option_and_proceed
      update_flow_trial_number
      post_and_validate(:shipping_method, :no_verify => [:page_title, :custom_assert])
    end

    def item_description
      @page.search('div.ch_itemDescrConf span.ch_standardBold')[0].text.strip rescue nil
    end

    def assert_description_matches_expected
      desc = CheckoutUtils.extract_alphabets_only(item_description)
      expected_desc = CheckoutUtils.extract_alphabets_only(@expected_description)
      errors = errors_for_unexpected(desc, expected_desc, "expected_description")
      raise_fatal(errors) if errors.any?
    end

    def fetch_order_total_data
      item_price, shipping_cost, tax = @page.search('div.ch_os_TotalLineItemValue').first(3).map{|i| CheckoutUtils.price_str_to_decimal(i.text) rescue nil}

      order_total = page_search_price('div.ch_os_TotalLineItemValue_total')

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

    def checkout_flow_trial_number_url
      "#{CHECKOUT_FLOW_URL}#{@checkout_flow_trial_number}"
    end

    def assert_checkout_flow_number_exists
      unless @checkout_flow_trial_number
        raise_fatal({:checkout_flow_trial_number => "Checkout flow trial number must be set before calling purchase method!"})
      end
    end

    def update_flow_trial_number
      @checkout_flow_trial_number = scrape_checkout_flow_trial_number
    end

    def scrape_checkout_flow_trial_number
      @page.search("input[name='execution']").attr('value').value rescue nil
    end

    def order_number
      @page.search('div.ch_confirmationOrderInfoDetail span.ch_standardBold')[0].text.gsub(/Order Number: /, '').strip rescue nil
    end

    def order_info_detail
      @page.search('div.ch_confirmationOrderInfoDetail')[0].to_s rescue nil
    end

    def fetch_complete_order_information
      data = {:order_number => order_number}
      assert_critical_order_info_is_not_nil([:order_number], data)
      {
        :response_code => SUCCESS_FLAG,
        :data => data.merge({:order_info_detail => order_info_detail})
      }
    end

    def remove_item_from_bag
      # agent_get necessary?
      agent_get(:remove_from_bag, :no_verify => [:custom_assert, :page_title])
      post_and_validate(:remove_from_bag, :no_verify => [:custom_assert, :page_title])
    end

    ## ALWAYS define this
    def additional_unloggable_values
      [cc_month_to_post]
    end

    def cc_month_to_post
      Date::MONTHNAMES[@credit_card_month.to_i]
    end

    def load_cookies_to_agent
      if @testing
        cookie_jar.load_from_hash(YAML.load_file(COOKIE_FILE_1))
      else
        assert_cookies_exist
        cookie_jar.load_from_hash(YAML.load(@cookies))
      end
    end

    ####################### methods called by #post_and_validate and #agent_get #######################

    def go_to_product_url
      @affiliate_url
    end

    def assert_for_go_to_product
      return if @page.is_a?(Mechanize::Page)
      raise_out_of_stock({:url => "Product page is not of type Mechanize::Page, but of class: #{@page.class}"},
                         {:parameters_used => go_to_product_url})
    end

    ADD_TO_BAG_URL = "http://www1.bloomingdales.com/bag/addto.ognc"

    def assert_for_add_to_bag(parameters_used)
      error_div = @page.search('div.pdp_errorText')
      if error_div.any?
        error_message = error_div.text.strip rescue 'Unknown Error.'
        raise_out_of_stock({:add_to_bag => "Adding item to the checkout bag failed for: #{error_message }"},
                           {:parameters_used => parameters_used})
      end
    end

    def add_to_bag_parameters
        {
          "ADDTOBAG_BUTTON" => "ADDTOBAG_BUTTON",
          "Action" => "",
          "CategoryID" => '',
          "ID" => @id,
          "ItemNumberCatalogCode" => "",
          "ParentCatID" => '',
          "PseudoCat" => "#{@coremetricsDepthPath}",
          "Quantity" => "1", # hard coded; will drop if needed to
          "SourceCustomerID" => "",
          "UPCID" => "noUPC_ID",
          "color" => @color_name,
          "size" => @size_name,
          "trackingCat" => '',
        }
      end

      GO_TO_SHIPPING_INFO_URL = "https://www.bloomingdales.com/signin/index.ognc"
      GO_TO_SHIPPING_INFO_PAGE_TITLE = "Shopping Bag - Shipping Information"

      def go_to_shipping_info_parameters
        {
          'Action' => '',
          'CHECKOUT_BUTTON'	=> 'CHECKOUT_BUTTON',
          'CHECKOUT_BUTTON.x' => '123',
          'CHECKOUT_BUTTON.y' =>	'18',
          'fromCheckout' => 'fromCheckout',
          'fromPage' => 'null',
        }
      end

      SKIP_PROFILE_CREATION_AND_GO_TO_SHIPPING_INFO_URL = "http://www1.bloomingdales.com/bag/index.ognc"
      SKIP_PROFILE_CREATION_AND_GO_TO_SHIPPING_INFO_PAGE_TITLE = "Shopping Bag - Shipping Information"

      def skip_profile_creation_and_go_to_shipping_info_parameters
        {
          'Action' => '',
          'CHECKOUT_BUTTON' =>	'CHECKOUT_BUTTON',
          'CHECKOUT_BUTTON.x' =>	'71',
          'CHECKOUT_BUTTON.y' =>	'14',
          'CategoryID' =>	'',
          'PromoCode' => @promo_code_1,
          'PromoCode2' => @promo_code_2,
          "QuantityMyself99|990___1___#{@vendor_scc_value}"	=> '1',
          'bagUrl' => '',
          "colorMyself99|990___1___#{@vendor_scc_value}"	=> '',
          'currencyCode' => '',
          'exchangeRateId' => '',
          'itemstate'	=> '0',
          'landedCostCoefficientId' => '',
          'shippingCountryCode' => '',
          "sizeMyself99|990___1___#{@vendor_scc_value}"	=> '',
          "typeMyself99|990___1___#{@vendor_scc_value}"	=> '',
        }
      end

      GO_TO_PROFILE_CREATION_URL = "http://www1.bloomingdales.com/bag/index.ognc"
      GO_TO_PROFILE_CREATION_PAGE_TITLE = "Bloomingdales.com - Shopping Bag"

      def go_to_profile_creation_parameters
        {
          'Action' => '',
          'CHECKOUT_BUTTON' =>	'CHECKOUT_BUTTON',
          'CHECKOUT_BUTTON.x' =>	'71',
          'CHECKOUT_BUTTON.y' =>	'14',
          'CategoryID' =>	'',
          'PromoCode' => @promo_code_1,
          'PromoCode2' => @promo_code_2,
          "QuantityMyself99|990___1___#{@vendor_scc_value}"	=> '1',
          'bagUrl' => '',
          "colorMyself99|990___1___#{@vendor_scc_value}"	=> '',
          'currencyCode' => '',
          'exchangeRateId' => '',
          'itemstate'	=> '0',
          'landedCostCoefficientId' => '',
          'shippingCountryCode' => '',
          "sizeMyself99|990___1___#{@vendor_scc_value}"	=> '',
          "typeMyself99|990___1___#{@vendor_scc_value}"	=> '',
        }
      end

      alias_method :shipping_address_url, :checkout_flow_trial_number_url

      def assert_for_shipping_address(parameters_used)
        error_hash = {}

        if @page.search('div.ch_headerError').any?
          error_hash[:main_message] = @page.search('div.ch_headerError').text.strip + "\n" rescue nil

          @page.search('div.ch_errorTextForm').each do |element|
            msg = element.text.strip + "\n"
            case msg
            when /first name/i
              error_hash[:first_name] = msg
            when /last name/i
              error_hash[:last_name] = msg
            when /address/i
              error_hash[:address_1] = msg
              error_hash[:address_2] = msg
            when /city/i
              error_hash[:city] = msg
            when /state/i
              error_hash[:state] = msg
            when /zip code/i
              error_hash[:zip] = msg
            when /phone/i
              error_hash[:phone] = msg
            else
              error_hash[:unknown] = 'Unknown field errored.'
            end
          end

          raise_retriable(error_hash, {:parameters_used => parameters_used})
        end
      end

      def shipping_address_parameters
        phone_num = split_phone_number_in_three(@phone)
        {
          '_eventId' =>	'saveShippingDetails',
          'currentShipment.shipmentAddress.address1' => @address_1,
          'currentShipment.shipmentAddress.address2' => @address_2,
          'currentShipment.shipmentAddress.city' => @city,
          'currentShipment.shipmentAddress.dayPhone.areaCode' =>	phone_num[0],
          'currentShipment.shipmentAddress.dayPhone.exchangeNbr' =>	phone_num[1],
          'currentShipment.shipmentAddress.dayPhone.subscriberNbr' =>	phone_num[2],
          'currentShipment.shipmentAddress.firstName' => @first_name,
          'currentShipment.shipmentAddress.lastName' => @last_name,
          'currentShipment.shipmentAddress.state' => @state,
          'currentShipment.shipmentAddress.zipCode' => @zip,
          'execution' =>	"#{@checkout_flow_trial_number}",
          'primary_nickName' => '',
          'registrantAddr_selected' => '',
          'selectedShippingAddress' =>	'newAddress',
        }
      end

      alias_method :shipping_method_url, :checkout_flow_trial_number_url

      def shipping_method_parameters
        {
          '_currentShipment.giftBox' => '',
          '_currentShipment.giftMessageBox' => '',
          '_currentShipment.giftReceipt' => '',
          '_eventId' => 'saveShippingOptions',
          'currentShipment.bodyGiftMessage' => '',
          'currentShipment.closingGiftMessage' => '',
          'currentShipment.gift' =>	'NO',
          'currentShipment.giftReceipt' =>	'Gift',
          'currentShipment.greetingGiftMessage' => '',
          'execution' =>	"#{@checkout_flow_trial_number}",
          'selectedShippingMethodCode' =>	'G', # express shipping is '2'
          'uniqueID' => '',
        }
      end

      BUY_ITEM_PAGE_TITLE = "Order Confirmation"
      alias_method :buy_item_url, :checkout_flow_trial_number_url
      alias_method :buy_item_headers, :cookie_header

      def assert_for_buy_item(parameters_used)
        error_hash = {}
        if @page.search('div.generalErrorBilling').any?
          error_hash[:main_message] = @page.search('div.generalErrorBilling').text.strip + "\n" rescue nil
          if error_hash[:main_message].match(/unable to process your order/i)
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

      def buy_item_parameters
        {
          '_eventId' =>	'placeOrder',
          'billingVB.promoCodes[0]' => '',
          'billingVB.promoCodes[1]' => '',
          'billingVB.promoToRemove' => '',
          'execution' =>	"#{@checkout_flow_trial_number}",
          'selectedItem' => '',
          'shipmentNickName' => '',
          'shipmentNumber' => '',
          'uniqueID' => ''
        }
      end

      BILLING_ADDRESS_PAGE_TITLE = "Shopping Bag - Order Review"
      alias_method :billing_address_url, :checkout_flow_trial_number_url

      def assert_for_billing_address(parameters_used)
        error_hash = {}
        if @page.search('div.generalErrorBilling span').any?
          error_hash[:main_message] = @page.search('div.generalErrorBilling span').text.strip + "\n" rescue nil

          @page.search('label.ch_errorTextForm').each do |element|
            msg = element.text.strip + "\n"
            case msg
            when /card type/i
              error_hash[:credit_card_type] = msg
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
            when /zip code/i
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

      def billing_address_parameters
        phone_num = split_phone_number_in_three(@billing_phone)
        {
          '_eventId' =>	'saveBilling',
          'ccNickName' => '',
          'contactEmail' => @email_address,
          'contactPhone.areaCode' => '',
          'contactPhone.exchangeNbr' => '',
          'contactPhone.subscriberNbr' => '',
          'contactVerifyEmail' => @email_address,
          'currentCreditCard.cvv2' => '',
          'currentGiftCard.giftCardNumber' => '',
          'egcNumberToRemove' => '',
          'execution' =>	"#{@checkout_flow_trial_number}",
          'giftCardEntered' => 'N',
          'index' => '',
          'newCreditCard.billingAddress.firstName' => @billing_first_name,
          'newCreditCard.billingAddress.lastName' => @billing_last_name,
          'newCreditCard.billingAddress.address1' => @billing_address_1,
          'newCreditCard.billingAddress.address2' => @billing_address_2,
          'newCreditCard.billingAddress.city' => @billing_city,
          'newCreditCard.billingAddress.state' => @billing_state,
          'newCreditCard.billingAddress.zipCode' => @billing_zip,

          'newCreditCard.billingAddress.dayPhone.areaCode' =>	phone_num[0],
          'newCreditCard.billingAddress.dayPhone.exchangeNbr' => phone_num[1],
          'newCreditCard.billingAddress.dayPhone.subscriberNbr' => phone_num[2],

          'newCreditCard.creditCardExpiryMonth' => cc_month_to_post,
          'newCreditCard.creditCardExpiryYear' => @credit_card_year,
          'newCreditCard.creditCardNumberBinder' =>	@credit_card_num,
          'newCreditCard.creditCardType' =>	CREDIT_CARD_TYPE[@credit_card_type.downcase],
          'newCreditCard.cvv' => @credit_card_ccv,

          'promoCodes[0]' => '',
          'promoCodes[1]' => '',
          'promoToRemove' => '',
          'securityWord' => '',
          'selectedBillingContactNumberOption' => 'billingPhone', # if this is 'phoneNumber', provide "contact_phone_area_code/exchange/subscriber numbers"
        }
      end

      REMOVE_FROM_BAG_URL = "http://www1.bloomingdales.com/bag/index.ognc"

      def remove_from_bag_parameters
        {
          "Action" => "DELETE_LINKMyself99|990___1___#{@vendor_scc_value}",
          "PromoCode" => "",
          "PromoCode2" => "",
          "QuantityMyself99|990___1___#{@vendor_scc_value}" => '1',
          "bagUrl" => "",
          "colorMyself99|990___1___#{@vendor_scc_value}" => '',
          "currencyCode" => '',
          "exchangeRateId" => '',
          "itemstate" => '0',
          "landedCostCoefficientId" => '',
          "shippingCountryCode" => '',
          "sizeMyself99|990___1___#{@vendor_scc_value}" => '',
          "typeMyself99|990___1___#{@vendor_scc_value}" => '',
        }
      end

  end
end


