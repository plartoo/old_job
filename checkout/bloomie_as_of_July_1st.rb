module Checkout
  class Bloomingdales < MechanizeCheckoutManager

    HOMEPAGE = "http://www.bloomingdales.com"
    ADD_TO_BAG_BUTTON_URL = "http://www1.bloomingdales.com/bag/addto.ognc"
    SHOPPING_BAG_URL = "http://www1.bloomingdales.com/bag/index.ognc"
    SIGNIN_URL = "https://www.bloomingdales.com/signin/index.ognc"
    CHECKOUT_FLOW_URL = "https://www.bloomingdales.com/checkoutswf/checkout-webflow?execution="

    SHOPPING_BAG_PAGE_TITLE = "Bloomingdales.com - Shopping Bag"
    SHOPPING_BAG_SHIPPING_INFO_PAGE_TITLE = "Shopping Bag - Shipping Information"
    BILLING_PAGE_TITLE = "Shopping Bag - Billing Information"
    REVIEW_PAGE_TITLE = "Shopping Bag - Order Review"
    CONFIRMATION_PAGE_TITLE = "Order Confirmation"

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
    ## Exit points
    PURCHASE = "purchase"

    def max_expected_secs_for_checkout
      15
    end

    def initialize(options)
      super(options)
    end

    def add_to_bag
      extract_category_id_and_product_id
      # we must go to product page once to make sure we see errors there when adding to bag fails
      go_to_product_page
      save_html_data_for_current_page("Add to bag => go_to_product_page", @page)

      add_to_bag_post_parameters = {
        "ADDTOBAG_BUTTON" => "ADDTOBAG_BUTTON",
        "Action" => "",
        "CategoryID" => @category_id,
        "ID" => @id,
        "ItemNumberCatalogCode" => "",
        "ParentCatID" => @category_id,
        "PseudoCat" => "Cat#{@category_id} #{@coremetricsDepthPath}",
        "Quantity" => "1", # hard coded; will drop if needed to
        "SourceCustomerID" => "",
        "UPCID" => "noUPC_ID",
        "color" => @color_name,
        "size" => @size_name,
        "trackingCat" => @category_id,
        }

      @page = @agent.post(ADD_TO_BAG_BUTTON_URL, add_to_bag_post_parameters)
      save_html_data_for_current_page("Add to bag => submitted POST request", @page)
      check_for_errors_on_product_detail_page(add_to_bag_post_parameters)
      proceed_to_checkout_from_item_detail_page
      save_html_data_for_current_page("Step 3", @page)
      proceed_to_checkout_from_shopping_bag_page
      save_html_data_for_current_page("fetcher_order_data => Step 2", @page)
      proceed_to_checkout_from_shopping_bag_shipping_information_page
      save_html_data_for_current_page("fetcher_order_data => Step 3", @page)
      ## this is for testing purpose, will go away or won't be used at all in production
      if @testing.any?
        @agent.cookie_jar.save_as("#{@cookie_file_out}")
      end

      {
        :response_code => SUCCESS_FLAG,
        :data => {:cookies => @agent.cookie_jar.jar}
      }
    end

    def proceed_to_checkout_from_shopping_bag_page_after_user_creation
      ### this must be modified if we have size/color variations
      checkout_post_parameters = {
          'Action' => '',
          'CHECKOUT_BUTTON' =>	'CHECKOUT_BUTTON',
          'CHECKOUT_BUTTON.x' =>	'71',
          'CHECKOUT_BUTTON.y' =>	'14',
          'CategoryID' =>	@category_id,
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

      @page = @agent.post(SHOPPING_BAG_URL, checkout_post_parameters)
      assert_on_page(@page.title, SHOPPING_BAG_SHIPPING_INFO_PAGE_TITLE, checkout_post_parameters)
    end

    def fetch_order_data
        extract_category_id_and_product_id
        if @testing.any? && File.exists?(@cookie_file_in)
          @cookies = YAML.load_file(@cookie_file_in)
        end
        raise_error_if_cookies_do_not_exist
        load_cookies_to_agent
        header = {"Cookie" => cookie_string}

        proceed_to_checkout_from_item_detail_page(header)
        save_html_data_for_current_page("fetcher_order_data => Step 1", @page)

        proceed_to_checkout_from_shopping_bag_page_after_user_creation
        save_html_data_for_current_page("fetcher_order_data => Step 2", @page)

        fill_out_shipping_address_info_and_proceed
        save_html_data_for_current_page("fetcher_order_data => Step 4", @page)
        fill_out_billing_address_info_and_proceed
        save_html_data_for_current_page("fetcher_order_data => Step 5", @page)

        return fetch_order_total_data
    end

    def assert_checkout_flow_number_exist?
      unless @checkout_flow_trial_number
        raise FatalError.build(
                          {:checkout_flow_trial_number => "Checkout flow trial number must be set before calling purchase method!"})
      end
    end

    def purchase
      # just for testing, but won't harm production if left without commenting out
      if @testing.any? && File.exists?(@cookie_file_in)
        @cookies = YAML.load_file(@cookie_file_in)
      end

      raise_error_if_cookies_do_not_exist
      load_cookies_to_agent
      header = {"Cookie" => cookie_string}

      assert_checkout_flow_number_exist?
      buy_item(header)
      save_html_data_for_current_page("Purchase => submitted POST request", @page)
      fetch_complete_order_information
    rescue => e
      remove_item_from_bag
      raise e
    end

    def test_checkout
      unless PURCHASE == @checkout_process
        extract_category_id_and_product_id

        go_to_product_page
        save_html_data_for_current_page("Step 1", @page)
        add_to_bag
        save_html_data_for_current_page("Step 2", @page)
        proceed_to_checkout_from_item_detail_page
        save_html_data_for_current_page("Step 3", @page)
        proceed_to_checkout_from_shopping_bag_page
        save_html_data_for_current_page("Step 4", @page)
        proceed_to_checkout_from_shopping_bag_shipping_information_page
        save_html_data_for_current_page("Step 5", @page)

        fill_out_shipping_address_info_and_proceed
        save_html_data_for_current_page("Step 6", @page)
        select_shipping_option_and_proceed
        save_html_data_for_current_page("Step 7", @page)
        fill_out_billing_address_info_and_proceed
        save_html_data_for_current_page("Step 8", @page)

        ## this is for testing purpose, will go away or won't be used at all in production
        if @testing.any?
          @agent.cookie_jar.save_as("#{@cookie_file}")
        end

        return fetch_order_total_data
      else
        if @testing.any? && File.exists?(@cookie_file)
          @cookies = YAML.load_file(@cookie_file)
        else
          raise "Cookie file may not exist"
        end

        raise_error_if_cookies_do_not_exist
        load_cookies_to_agent
        header = {"Cookie" => cookie_string}
        buy_item(header)
        save_html_data_for_current_page("Step 9", @page)
        fetch_complete_order_information
      end
    rescue => e
      remove_item_from_bag
      raise e
    end

    private

    def extract_category_id_and_product_id
      @category_id = @url.match(/CategoryID=(\d+)/)[1] rescue nil
      @id = @url.match(/\?ID=(\d+)/)[1] rescue nil
    end

    ## only used for testing purpose
    def write_out_page(page)
      File.open('woohoo.html','w'){|f|
        f.puts page.content
      }
    end

    def go_to_product_page
      @page = @agent.get(@url)
      unless @page.is_a?(WWW::Mechanize::Page)
        raise FatalError.build(
                          {:url => "Product page is not of type WWW::Mechanize::Page"},
                          [@url])
      end
    end

    def check_for_errors_on_product_detail_page(parameters_used)
      error_div = @page.search('div.pdp_errorText')
      if error_div.any?
        error_message = error_div.text.strip rescue 'Unknown Error.'
        raise FatalError.build(
                          {:add_to_bag => "Adding item to the checkout bag failed for: #{error_message }"},
                          [parameters_used])
      end
    end

    def assert_on_page(cur_pg_title, expected_pg_title, parameters_used)
      unless cur_pg_title.match(/#{expected_pg_title}/i)
        raise FatalError.build(
                          {:expected_page_does_not_appear => "#{expected_pg_title} page doesn't appear"},
                          [parameters_used],
                          [expected_pg_title])
      end
    end

    def proceed_to_checkout_from_item_detail_page(headers={})
      parameters = {
                      :url => "#{SHOPPING_BAG_URL}",
                      :headers => headers
                    }
      @page = @agent.get(parameters)

      assert_on_page(@page.title, SHOPPING_BAG_PAGE_TITLE, parameters)
    end

    def proceed_to_checkout_from_shopping_bag_page
      ### this must be modified if we have size/color variations
      checkout_post_parameters = {
          'Action' => '',
          'CHECKOUT_BUTTON' =>	'CHECKOUT_BUTTON',
          'CHECKOUT_BUTTON.x' =>	'71',
          'CHECKOUT_BUTTON.y' =>	'14',
          'CategoryID' =>	@category_id,
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

      @page = @agent.post(SHOPPING_BAG_URL, checkout_post_parameters)
      assert_on_page(@page.title, SHOPPING_BAG_PAGE_TITLE, checkout_post_parameters)
    end

    def proceed_to_checkout_from_shopping_bag_shipping_information_page
      checkout_without_profile_post_parameters = {
          'Action' => '',
          'CHECKOUT_BUTTON'	=> 'CHECKOUT_BUTTON',
          'CHECKOUT_BUTTON.x' => '123',
          'CHECKOUT_BUTTON.y' =>	'18',
          'fromCheckout' => 'fromCheckout',
          'fromPage' => 'null',
        }
      @page = @agent.post(SIGNIN_URL, checkout_without_profile_post_parameters)
      assert_on_page(@page.title, SHOPPING_BAG_SHIPPING_INFO_PAGE_TITLE, checkout_without_profile_post_parameters)
    end

    def split_phone_number_to_three_parts(phone_str_with_dash)
      # assuming the user enters 10-digit phone num with or without dash
      phone_num_without_dash = phone_str_with_dash.delete("-")
      unless phone_num_without_dash.size == 10
        raise RetriableError.build(
                          {:split_phone_number_to_three_parts => "Phone Number is not 10 digit as expected"},
                          [phone_str_with_dash]
                          )
      end
      parts = phone_num_without_dash.match(/^(\d{3})(\d{3})(\d{4})/i)
      [parts[1],parts[2],parts[3]]
    end

    def check_if_we_have_shipping_method_option_radio_buttons(parameters_used)
      @page.search('div#globalContentContainer div.ch_shippingOptionsContainer form').any?
#        raise FatalError.build(
#                          {:expected_page_does_not_appear => "Shipping Methods Options page doesn't seem to appear"},
#                          [parameters_used])
#      end
    end

    def collect_forms_that_errored_on_shipping_address_page_and_raise_error_appropriately(parameters_used)
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

        raise RetriableError.build(
                          error_hash,
                          [parameters_used])
      end
    end

    def fill_out_shipping_address_info_and_proceed
      phone_num = split_phone_number_to_three_parts(@phone)
      @checkout_flow_trial_number = @page.search("input[name='execution']").attr('value').value rescue nil
      shipping_address_post_parameters = {
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

      @page = @agent.post("#{CHECKOUT_FLOW_URL}#{@checkout_flow_trial_number}", shipping_address_post_parameters)
      collect_forms_that_errored_on_shipping_address_page_and_raise_error_appropriately(shipping_address_post_parameters)
      if check_if_we_have_shipping_method_option_radio_buttons(shipping_address_post_parameters)
        select_shipping_option_and_proceed
        save_html_data_for_current_page("From shipping address info page => Select shipping option and proceed", @page)
      end
      assert_on_page(@page.title, BILLING_PAGE_TITLE, shipping_address_post_parameters)
    end

    def select_shipping_option_and_proceed
      @checkout_flow_trial_number = @page.search("input[name='execution']").attr('value').value rescue nil
      shipping_method_option_post_parameters = {
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

      @page = @agent.post("#{CHECKOUT_FLOW_URL}#{@checkout_flow_trial_number}", shipping_method_option_post_parameters)
    end

    def collect_forms_that_errored_on_billing_info_page_and_raise_error_appropriately(parameters_used)
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

        raise RetriableError.build(
                          error_hash,
                          [parameters_used])
      end
    end

    def fill_out_billing_address_info_and_proceed
      phone_num = split_phone_number_to_three_parts(@billing_phone)

      @checkout_flow_trial_number = @page.search("input[name='execution']").attr('value').value rescue nil
      billing_info_post_parameters = {
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

          'newCreditCard.creditCardExpiryMonth' => Date::MONTHNAMES[@credit_card_month.to_i],
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

      @page = @agent.post("#{CHECKOUT_FLOW_URL}#{@checkout_flow_trial_number}", billing_info_post_parameters )

      collect_forms_that_errored_on_billing_info_page_and_raise_error_appropriately(billing_info_post_parameters)
      assert_on_page(@page.title, REVIEW_PAGE_TITLE, billing_info_post_parameters)
    end

    def errors_for_unexpected(actual, expected, desc)
      if actual == expected
        {}
      else
        {desc.to_sym => "#{desc} doesn't match. Expected: #{expected} but got #{actual}"}
      end
    end

    def collect_errors_if_expected_description_and_item_price_do_not_match(description, item_price)
      errors = {}

      desc = CheckoutUtils.extract_alphabets_only(description)
      expected_desc = CheckoutUtils.extract_alphabets_only(@expected_description)
      errors.merge!errors_for_unexpected(desc, expected_desc, "expected_description")

      errors.merge!errors_for_unexpected(item_price.to_f, @expected_item_price.to_f, "expected_item_price")

      errors
    end

    def collect_errors_if_expected_shipping_and_tax_and_total_do_not_match(shipping, tax, order_total)
      errors = {}

      errors.merge!errors_for_unexpected(shipping.to_f, @expected_shipping.to_f, "expected_shipping")
      errors.merge!errors_for_unexpected(tax.to_f, @expected_tax.to_f, "expected_tax")
      errors.merge!errors_for_unexpected(order_total.to_f, @expected_order_total.to_f, "expected_order_total")

      errors
    end

    def assert_critical_order_info_is_not_nil(keys_to_check, data)
      errors = {}
      keys_to_check.each do |k|
        unless data[k]
          errors.merge!({k => "#{k} is missing!!"})
        end
      end

      if errors.any?
        raise FatalError.build(
                  errors,
                  [],
                  [data])
      end
    end

    def calculate_discount(total, costs)
      line_total = costs.inject{|sum,x| sum += x}
      total - line_total
    end

    def assert_not_negative(value)
      if value.to_f < 0.0
        raise FatalError.build(
                  {:discount => "Value is negative"},
                  [value])
      end
    end

    def fetch_order_total_data
      description = @page.search('div.ch_itemDescrConf span.ch_standardBold')[0].text.strip rescue nil
      item_price = @page.search('div.ch_os_TotalLineItemValue')[0].text.strip rescue nil
      item_price = CheckoutUtils.price_str_to_float(item_price)

      shipping_cost = @page.search('div.ch_os_TotalLineItemValue')[1].text.strip rescue nil
      shipping_cost = CheckoutUtils.price_str_to_float(shipping_cost)

      tax = @page.search('div.ch_os_TotalLineItemValue')[2].text.strip rescue nil
      tax = CheckoutUtils.price_str_to_float(tax)

      order_total = @page.search('div.ch_os_TotalLineItemValue_total')[0].text.strip rescue nil
      order_total = CheckoutUtils.price_str_to_float(order_total)

      data = {
                :item_price => item_price,
                :shipping_cost => shipping_cost,
                :tax => tax,
                :order_total => order_total,
              }
      assert_critical_order_info_is_not_nil([:item_price, :shipping_cost, :tax, :order_total], data)

      errors = collect_errors_if_expected_description_and_item_price_do_not_match(description, item_price)
      if errors.any?
        raise FatalError.build(
          errors,
          [@expected_description, @expected_item_price], []
        )
      end

      discount = calculate_discount(order_total, [item_price, shipping_cost, tax]) rescue nil
      assert_not_negative(discount)
      
      @checkout_flow_trial_number = @page.search("input[name='execution']").attr('value').value rescue 'e2s4'
      ## this is for testing purpose, will go away or won't be used at all in production
      if @testing.any?
        @agent.cookie_jar.save_as("#{@cookie_file_out}")
      end

      {
        :response_code => SUCCESS_FLAG,
        :data => data.merge({
                            :discount => discount,
                            :cookies => @agent.cookie_jar.jar,
                            :checkout_flow_trial_number => @checkout_flow_trial_number,
                            })
      }
    end

    def check_if_credit_card_verification_failed(parameters_used)
      error_hash = {}
      msg = 'error processing order'
      if @page.search('div.generalErrorBilling').any?
        error_hash[:main_message] = @page.search('div.generalErrorBilling').text.strip + "\n" rescue nil
        if error_hash[:main_message].match(/unable to process your order/i)
            error_hash[:credit_card_type] = error_hash[:main_message]
            error_hash[:credit_card_num] = error_hash[:main_message]
            error_hash[:credit_card_month] = error_hash[:main_message]
            error_hash[:credit_card_year] = error_hash[:main_message]
        end

        raise RetriableError.build(
                          error_hash,
                          [parameters_used])
      end
    end

    def fetch_complete_order_information
      order_number = @page.search('div.ch_confirmationOrderInfoDetail span.ch_standardBold')[0].text.strip rescue nil
      item_price = @page.search('div.ch_confirmationOrderTotals div.ch_orderTotalLineItemValue')[0].text.strip rescue nil
      item_price = CheckoutUtils.price_str_to_float(item_price)

      shipping_cost = @page.search('div.ch_confirmationOrderTotals div.ch_orderTotalLineItemValue')[1].text.strip rescue nil
      shipping_cost = CheckoutUtils.price_str_to_float(shipping_cost)

      tax = @page.search('div.ch_confirmationOrderTotals div.ch_orderTotalLineItemValue')[2].text.strip rescue nil
      tax = CheckoutUtils.price_str_to_float(tax)

      order_total = @page.search('div.ch_orderTotalLineItemBox_total div.ch_orderTotalLineItemValue_total').text.strip rescue nil
      order_total = CheckoutUtils.price_str_to_float(order_total)

      data = {
        :order_number => order_number,
        :item_price => item_price,
        :shipping_cost => shipping_cost,
        :tax => tax,
        :order_total => order_total,
      }
      assert_critical_order_info_is_not_nil([:order_number, :item_price, :shipping_cost, :tax, :order_total], data)

      errors = collect_errors_if_expected_description_and_item_price_do_not_match(item_desc, item_price)
      errors.merge!(collect_errors_if_expected_shipping_and_tax_and_total_do_not_match(shipping_cost, tax, order_total))

      if errors.any?
        raise FatalError.build(
          errors,
          [@expected_description, @expected_item_price, @expected_shipping, @expected_tax, @expected_order_total], elements_to_check
        )
      end

      # make sure to calculate discount only after the above checks
      discount = calculate_discount(order_total, [item_price, shipping_cost, tax]) rescue nil
      assert_not_negative(discount)

      order_info_detail = @page.search('div.ch_confirmationOrderInfoDetail')[0].to_s rescue nil
      billing_address = @page.search('div.ch_confirmationBillingAddress')[0].text.strip rescue nil
      shipping_address = @page.search('div.ch_confirmationShipAddress')[0].text.strip rescue nil
      shipping_method = @page.search('div.ch_confirmationShipMethod')[0].text.strip rescue nil
      shipping_contact_info = @page.search('div.ch_confirmationShipContactinfo')[0].text.strip rescue nil
      item_desc = @page.search('div.ch_itemSummaryWide div.ch_itemDescrWide')[0].text.strip rescue nil

      {:response_code => SUCCESS_FLAG,
        :data => data.merge(
                  {
                    :discount => discount,
                    # other info we may or may not use
                    :order_info_detail => order_info_detail,
                    :billing_address => billing_address,
                    :shipping_address => shipping_address,
                    :shipping_method => shipping_method,
                    :shipping_contact_info => shipping_contact_info,
                    :item_desc => item_desc,
                  }
        )}
    end

    def buy_item(header={})
      buy_post_parameters = {
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
      @page = @agent.post("#{CHECKOUT_FLOW_URL}#{@checkout_flow_trial_number}",
                          buy_post_parameters, header)

      check_if_credit_card_verification_failed(buy_post_parameters)
      assert_on_page(@page.title, CONFIRMATION_PAGE_TITLE, buy_post_parameters)
    end

    def remove_item_from_bag
      @page = @agent.get(SHOPPING_BAG_URL)
      save_html_data_for_current_page("Removing item from shopping bag -- Shopping bag page", @page)

      remove_bag_post_parameters = {
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

      @page = @agent.post(SHOPPING_BAG_URL, remove_bag_post_parameters)
      save_html_data_for_current_page("Removing item from shopping bag -- Shopping bag page", @page)
    end

    def cookies_exist?
      return false unless @cookies
      return false if @cookies.empty?
      true
    end

    def raise_error_if_cookies_do_not_exist
      unless cookies_exist?
          raise FatalError.build(
            {:cookies => "No cookie no purchase."},
            [@cookies]
        )
      end
    end

    def load_cookies_to_agent
      @agent.cookie_jar.load_from_hash(@cookies)
    end

    # need to raise errors when expected key is missing?
    def cookie_string
      str = ''
      ['HISTORY_KEY','GCs'].each do |key|
        value = @agent.cookie_jar.jar['bloomingdales.com'][key].to_s
        str += value
        str += (value.any? ? '; ' : '')
      end
      str.gsub(/; $/,'')
    end

  end
end



