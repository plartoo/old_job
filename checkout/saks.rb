require File.expand_path(File.join(File.dirname(__FILE__),"..","lib","checkout_manager"))

class CheckoutManager
  class Saksfifthavenue < CheckoutManager

    HOMEPAGE = "http://saksfifthavenue.com"

    UNSUBSCRIBE_URL = "http://www.saksfifthavenue.com/main/EmlUnsub.jsp"

    ## Exit points
    FETCH_ORDER_TOTAL_DATA = "fetch_order_total_data"

    def do_checkout
      @selenium.delete_all_visible_cookies

      go_to_item_and_begin_checkout
      raise_error_if_out_of_time

      verify_bag_contents
      raise_error_if_out_of_time

      enter_user_email_address_to_continue
      raise_error_if_out_of_time

      enter_shipping_and_billing_info
      raise_error_if_out_of_time

      if FETCH_ORDER_TOTAL_DATA == @checkout_process
        return fetch_order_total_data
      end

      enter_credit_card_info
      raise_error_if_out_of_time

      validate_final_order_info
      raise_error_if_out_of_time

      do_final_checkout

      capture_final_order_confirmation_data
    end

    def go_to_item_and_begin_checkout

      go_to! @url, "Error visiting initial url.", :invalid_product_url

      choose_from_drop_down "ADD_CART_ITEM_ARRAY<>sku_id", "value=regexp:#{@vendor_scc_value}", 
              "Error selecting vendor_scc_value, does it exist?", :vendor_scc_value
      click! "//option[@value='#{@vendor_scc_value}']", {:message => "Error selecting vendor_scc_value, is it valid?", :data_code => :vendor_scc_value}

      click_and_wait! "//input[@name='checkout']", {:wait_for => :page, :timeout_in_seconds => 30, :message => "Error adding item to shopping bag", :data_code => :shopping_bag_add_fail}

      process_until_block_returns_true(10, "Checkout button didn't appear", :shopping_bag_add_fail) do
        @selenium.is_element_present("//a[@id='checkoutLink']")
      end

      click! "//a[@id='checkoutLink']", {:wait_for => :page, :timeout_in_seconds => 30, :message => "Error clicking checkout and going to shopping bag", :data_code => :shopping_bag_goto_fail}

      process_until_block_returns_true(10, "Shopping cart content doesn't appear", :shopping_bag_goto_fail) do
        @selenium.is_element_present("//h6[@class='item-shortDesc']")
      end
    end

    def verify_bag_contents
      description = %Q("#{@selenium.get_text("//h5[@class='item-name']")} #{@selenium.get_text("//h6[@class='item-shortDesc']")})
      description = description.downcase.gsub(/[^a-z0-9]/, '')
      expected_description = @expected_description.downcase.gsub(/[^a-z0-9]/, '')
      assert_equal expected_description, description,
                        "Product description doesn't match", :expected_description

      process_until_block_returns_true(10, "Item price doesn't appear", :shopping_bag_contents_error) do
        @selenium.is_element_present("//span[@class='item-ext-price']") && "" != @selenium.get_text("//span[@class='item-ext-price']")
      end

      assert_equal_price @expected_item_price, @selenium.get_text("//span[@class='item-ext-price']"), "Product price doesn't match", :expected_item_price

      click! "//img[@alt='Checkout']", {:wait_for => :page, :timeout_in_seconds => 30, :message => "Error checking out from shopping bag", :data_code => :shopping_bag_checkout}
    end

    def enter_user_email_address_to_continue
      process_until_block_returns_true(5, "Email entry request box didn't show up.", :email_address_fail) do
        @selenium.is_text_present("* Email address")
      end

      type_into_field "loginGuestEmail", @email_address, "Error entering user email address", :email_address_fail
      click! "//a[@id='jsGuestCheckout']/img", {:wait_for => :page, :timeout_in_seconds => 30, :message => "Couldn't click guest checkout button", :data_code => :email_address_fail}

      process_until_block_returns_true(10,"Couldn't access shipping info page", :shipping_fields_error, RetriableError) do
        if @selenium.is_element_present("//div[@id='loginGuestEmail-wrap']/div[@class='errorMsg']")
          raise FatalError.build_with_data("Email address couldn't be entered correctly",{:response_code => FATAL_ERROR_KEY, :data => [:email_address_fail]})
        end

        @selenium.is_text_present("SHIPPING ADDRESS") rescue false
      end
    end

    def enter_shipping_and_billing_info
      shipping_info = {
        "shipFirst" => @first_name,
        "shipMI" => @middle_name ? @middle_name[0..0] : "",
        "shipLast" => @last_name,
        "shipCompany" => @company_Name,
        "shipAddress1" => @address_1,
        "shipAddress2" => @address_2,
        "shipCity" => @city,
        "shipZip" => @zip_code,
        "shipPhone" => @phone,
      }

      shipping_info.each do |field, value|
        process_until_block_returns_true(10, "Couldn't type in #{field}", :shipping_fields_error, RetriableError) do
          @selenium.is_element_present(field)
        end
        type_into_field field, value, "Error entering shipping data", :shipping_fields_error
      end

      process_until_block_returns_true(10, "Couldn't select shipping state", :shipping_fields_error, RetriableError) do
          @selenium.is_element_present("shipState")
        end
      choose_from_drop_down "shipState", "value=regexp:#{@state}", "Error entering shipping state", :shipping_fields_error
      click! "//option[@value='#{@state}']"

      raise FatalError.build_with_data("separate_billing_address must be \"true\" or \"false\"",{:response_code => FATAL_ERROR_KEY, :data => nil}) unless ["true","false"].include?(@separate_billing_address)

      if "true" == @separate_billing_address
        ### Clicking actually unchecks the box, making a separate billing address necessary
        click! "makeBilling", {:message => "Enabling billing to be separate address"}
      end


      click! "//img[@alt='Continue']", {:wait_for => :page, :timeout_in_seconds => 30, :message => "Finished shipping info"}

      ### After some processing delay, one of three things will happen
      ### 1. Post office check fails
      ### 2. We get errors on the address fields being invalid
      ### 3. We get the next page.
      process_until_block_returns_true(10,"Page loaded slowly, can retry.",:shipping_fields_error,RetriableError) do
        if @selenium.is_element_present("//img[@alt='Use Address as Entered']")
          raise FatalError.build_with_data("Post Office address confirmation blocking progress.",{:response_code => FATAL_ERROR_KEY, :data => nil})
        end

        verify_fields(
          [
            {:field => :first_name, :selector => "//div[@id='shipFirst-wrap']/div[@class='errorMsg']"},
            {:field => :last_name, :selector => "//div[@id='shipLast-wrap']/div[@class='errorMsg']"},
            {:field => :address_1, :selector => "//div[@id='shipAddress1-wrap']/div[@class='errorMsg']"},
            {:field => :city_name, :selector => "//div[@id='shipCity-wrap']/div[@class='errorMsg']"},
            {:field => :state, :selector => "//div[@id='shipState-wrap']/div[@class='errorMsg']"},
            {:field => :zip, :selector => "//div[@id='shipZip-wrap']/div[@class='errorMsg']"},
            {:field => :phone, :selector => "//div[@id='shipPhone-wrap']/div[@class='errorMsg']"},
          ],"Invalid shipping data input detected"
        )

        if should_enter_billing_address?
          billing_info = {
            "billFirst" => @billing_first_name,
            "billMI" => @billing_middle_name ? @billing_middle_name[0..0] : "",
            "billLast" => @billing_last_name,
            "billCompany" => @billing_company_Name,
            "billAddress1" => @billing_address_1,
            "billAddress2" => @billing_address_2,
            "billCity" => @billing_city,
            "billZip" => @billing_zip_code,
            "billPhone" => @billing_phone,
          }
          billing_info.each do |field, value|
            process_until_block_returns_true(10, "Couldn't type in #{field}", :billing_fields_error, RetriableError) do
              @selenium.is_element_present(field)
            end
            type_into_field field, value, "Error entering billing data"
          end

          process_until_block_returns_true(10, "Couldn't select billing state", :billing_fields_error, RetriableError) do
            @selenium.is_element_present("billState")
          end
          choose_from_drop_down "billState", "value=regexp:#{@billing_state}", "Error entering billing state", :billing_fields_error
          click! "//option[@value='#{@billing_state}']", {:message => "Selecting billing state", :data_code => :billing_fields_error}

          @billing_address_entered = true

          click! "//img[@alt='Apply']", {:wait_for => :page, :timeout_in_seconds => 30, :message => "Submitting billing info", :data_code => :billing_fields_error}
        end

        verify_fields(
          [
            {:field => :billing_first_name, :selector => "//div[@id='billFirst-wrap']/div[@class='errorMsg']"},
            {:field => :billing_last_name, :selector => "//div[@id='billLast-wrap']/div[@class='errorMsg']"},
            {:field => :billing_address_1, :selector => "//div[@id='billAddress1-wrap']/div[@class='errorMsg']"},
            {:field => :billing_city_name, :selector => "//div[@id='billCity-wrap']/div[@class='errorMsg']"},
            {:field => :billing_state, :selector => "//div[@id='billState-wrap']/div[@class='errorMsg']"},
            {:field => :billing_zip, :selector => "//div[@id='billZip-wrap']/div[@class='errorMsg']"},
            {:field => :billing_phone, :selector => "//div[@id='billPhone-wrap']/div[@class='errorMsg']"},
          ],"Invalid billing data input detected"
        )

        @selenium.is_element_present("//select[@id='payCC']")
      end
    end

    def enter_credit_card_info
      type_into_field "payCCNum", @credit_card_num, "Error entering credit card number", :cc_num_field
      type_into_field "payCCName", @credit_card_holder_name, "Error entering credit card holder name", :cc_holder_name_field
      type_into_field "payCCV", @credit_card_ccv, "Error entering credit card ccv", :cc_ccv_field
      type_into_field "promoCodeEntry", (@coupon_code || ""), "Error entering promo code", :promo_code_field

      choose_from_drop_down "payCC", "label=#{@credit_card_type}", "Error selecting credit card type", :selecting_cc_type
      choose_from_drop_down "ccMonth", "label=#{@credit_card_month}", "Error selecting credit card month", :selecting_cc_month
      choose_from_drop_down "ccYear", "label=#{@credit_card_year}", "Error selecting credit card year", :selecting_cc_year
      click! "//img[@alt='Continue']", {:wait_for => :page, :timeout_in_seconds => 30, :message => "Finished inputting CC info", :data_code => :cc_fields_error}

      process_until_block_returns_true(10, "Page loaded slowly, can retry.", :cc_fields_error, RetriableError) do
        verify_fields(
          [
            {:field => :credit_card_type, :selector => "//div[@id='payCC-wrap']/div[@class='errorMsg']"},
            {:field => :credit_card_number, :selector => "//div[@id='payCCNum-wrap']/div[@class='errorMsg']"},
            {:field => :credit_card_holder_name, :selector => "//div[@id='payCCName-wrap']/div[@class='errorMsg']"},
            {:field => :credit_card_month, :selector => "//div[@id='ccMonth-wrap']/div[@class='errorMsg']"},
            {:field => :credit_card_ccv, :selector => "//div[@id='payCCV-wrap']/div[@class='errorMsg']"},
            {:field => :coupon_code, :selector => "//div[@id='promoCodeEntry-wrap']/div[@class='errorMsg']"},
          ],"Invalid credit card data input detected"
        )

        @selenium.is_element_present("//img[@alt='Place Order']")
      end
    end

    def validate_final_order_info
      [
        [@expected_shipping, "//span[@id='jsVal-shippingCost']", "Validating expected shipping", :expected_shipping],
        [@expected_tax, "//span[@id='jsVal-tax']", "Validating expected tax", :expected_tax],
        [@expected_total_price, "//span[@id='jsVal-grandTotal']", "Validating expected total price", :expected_total_price],
      ].each do |expected, selector, message, data_code|
        assert_equal_price expected, @selenium.get_text(selector), message, data_code
      end
    end

    def do_final_checkout
      click! "//img[@alt='Place Order']", {:wait_for => :page, :timeout_in_seconds => 60, :message => "Clicked \"Place Order\"", :data_code => :checkout_fail}
      process_until_block_returns_true(10,"Could not complete final checkout", :checkout_fail, RetriableError) do
        verify_fields(
          [
            {:field => :credit_card_validation, :selector => "//div[@class='jsResponseError']/div[contains(@class, 'payment')]"},
          ],"Credit card validation failed, some CC component wasn't valid."
        )
        @selenium.is_text_present("Thank You for Ordering")
      end
    end

    def capture_final_order_confirmation_data
      save_html_data_for_current_page("Order has been placed confirmation page.")
      #### Now we're on the post-purchase, confirmation page
      # Order #65048814 â¢ 05/25/11 â¢ In Process
      response_code = SUCCESS_FLAG
      begin
        order_number_string = @selenium.get_text("//div[@id='confirm-intro']/div[1]/h1")
        actual_order_number = order_number_string[/Order #(.*?) /,1] || order_number_string
        billing_address = @selenium.get_text("jsVal-billingAddress")
        shipping_address = @selenium.get_text("//div[@class='shipping-summary']/dl/dd/p")

        final_order_total = @selenium.get_text("jsVal-grandTotal")
        tax = @selenium.get_text("jsVal-tax")
        quantity = @selenium.get_text("//span[@class='quantity-value']")

        est_delivery_date = @selenium.get_text("//dl[@class='shipping-method']/dd")

        email_address = @selenium.get_text("jsVal-emailAddress")
        cc_usage = @selenium.get_text("jsVal-creditCard")
      rescue => e
        # Want to capture as much of that data as possible
        # Set the success flag to partial, since we don't have all the data possibly
        response_code = PARTIAL_SUCCESS
      end
      {:response_code => response_code,
        :data => {
          :order_number => actual_order_number,
          :final_order_total => final_order_total,
          :tax => tax,
          :quantity => quantity,
          :est_delivery_date => est_delivery_date,
          :billing_address => billing_address,
          :shipping_address => shipping_address,
          :email_address => email_address,
          :cc_usage => cc_usage,
        }
      }
    end

    def should_enter_billing_address?
      !@billing_address_entered && @selenium.is_element_present("//div[@id='billing-address-layer-wrap']") && @separate_billing_address
    end

    def fetch_order_total_data
      final_order_total = @selenium.get_text("jsVal-grandTotal")
      tax = @selenium.get_text("jsVal-tax")
      shipping_cost = @selenium.get_text("jsVal-shippingCost")

      {:response_code => SUCCESS_FLAG, :data => {:order_total => final_order_total, :tax => tax, :shipping_cost => shipping_cost}}
    end


    def do_unsubscribe
      @selenium.delete_all_visible_cookies
      go_to! UNSUBSCRIBE_URL

      type_into_field "oldEmail", @email_address, "Error entering email address", :email_address
      sleep 1 # Saks needs a pause here before we can click "unsubscribe"
      click! "unsubscribe", {:wait_for => :page, :timeout_in_seconds => 30, :message => "Error clicking unsubscribe", :data_code => :unsub_button}
      
      process_until_block_returns_true(10,"Could not complete unsubscribe", :unsubscribe_fail, RetriableError) do
        if @selenium.alert?
          raise RetriableError.build_with_data("Invalid email address, encountered alert box.",{:data => [:invalid_email_address]})
        end

        @selenium.is_text_present("YOU HAVE BEEN REMOVED FROM OUR E-MAIL LIST.\n\nCLICK HERE TO VISIT SAKS.COM.")
      end
      
      {:response_code => SUCCESS_FLAG}
    end
    
  end
end
