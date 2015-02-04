require File.join(File.dirname(__FILE__),"test_helper")
require File.join(File.dirname(__FILE__),'..','managers','saksfifthavenue')

class SaksfifthavenueCheckoutManagerTest < Test::Unit::TestCase

  def setup

    @product_url = "http://www.saksfifthavenue.com/main/ProductDetail.jsp?FOLDER%3C%3Efolder_id=2534374306418048&PRODUCT%3C%3Eprd_id=845524446381307&R=478995750031&P_name=Lisa+Marie+Fernandez&N=1553+306418048&bmUID=i.Wj6Tr"
    @vendor_scc_value = "1689949377155075"

    @expected_item_price = "419.99"
    @expected_description = "The Farrah Dress"

    @expected_shipping = "17.00"
    @expected_total_price = "476.89"
    @expected_tax = "39.90"

    @user_email_address = "phyo@xxx.com"

    @user_zip_code = "94107"
    @user_address_1 = "410 Townsend St., Suite 150"
    @user_address_2 = ""
    @user_address_3 = ""
    @user_city = "San Francisco"
    @user_first_name = "Shop"
    @user_last_name = "To Me"
    @user_middle_name = "I"
    @user_phone = "650-555-1234"
    @user_state = "CA"

    @separate_billing_address = true

    @user_billing_zip_code = "94107"
    @user_billing_address_1 = "410 Townsend St., Suite 150"
    @user_billing_address_2 = ""
    @user_billing_address_3 = ""
    @user_billing_city = "San Francisco"
    @user_billing_first_name = "Shop"
    @user_billing_last_name = "To Me"
    @user_billing_middle_name = "I"
    @user_billing_phone = "650-555-1234"
    @user_billing_state = "CA"
    @user_billing_country = "US"

    @credit_card_type = "VISA"
    @credit_card_num = "4000000000000000"
    @credit_card_holder_name = "Shop It To Me"
    @credit_card_month = "1"
    @credit_card_year = "2012"
    @credit_card_ccv = "999"

    @coupon_code = "SPRINGSFA"

    @options = {
      :url => @product_url,

      :product_url => @product_url,
      :vendor_scc_value => @vendor_scc_value,

      :expected_item_price => @expected_item_price,
      :expected_description => @expected_description,

      :expected_shipping => @expected_shipping,
      :expected_total_price => @expected_total_price,
      :expected_tax => @expected_tax,

      :user_zip_code => @user_zip_code,
      :user_email_address => @user_email_address,
      :user_address_1 => @user_address_1,
      :user_address_2 => @user_address_2,
      :user_address_3 => @user_address_3,
      :user_city => @user_city,
      :user_first_name => @user_first_name,
      :user_last_name => @user_last_name,
      :user_middle_name => @user_middle_name,
      :user_phone => @user_phone,
      :user_state => @user_state,

      :billing_zip_code => @billing_zip_code,
      :billing_email_address => @billing_email_address,
      :billing_address_1 => @billing_address_1,
      :billing_address_2 => @billing_address_2,
      :billing_address_3 => @billing_address_3,
      :billing_city => @billing_city,
      :billing_first_name => @billing_first_name,
      :billing_last_name => @billing_last_name,
      :billing_middle_name => @billing_middle_name,
      :billing_phone => @billing_phone,
      :billing_state => @billing_state,
      :billing_country => @billing_country,

      :separate_billing_address => @separate_billing_address,
      
      :credit_card_type => @credit_card_type,
      :credit_card_num => @credit_card_num,
      :credit_card_holder_name => @credit_card_holder_name,
      :credit_card_month => @credit_card_month,
      :credit_card_year => @credit_card_year,
      :credit_card_ccv => @credit_card_ccv,

      :coupon_code => @coupon_code,
    }
  end

  def test_raises_error_with_no_product_url

    options = {
      :host => "localhost",
      :timeout_in_second => 90,
      :port => 4444,
      :url => nil,
      :browser => "*firefox",
    }
    manager = Saksfifthavenue.new(options)
    assert_raise Selenium::CommandError do
      manager.checkout
    end

  ensure
    manager.teardown
  end

  VARIABLES_TO_ERRORS = {
    :product_url => CheckoutManager::FATAL_ERROR_KEY,
    :vendor_scc_value => CheckoutManager::FATAL_ERROR_KEY,
    :expected_item_price => CheckoutManager::FATAL_ERROR_KEY,
    :expected_description => CheckoutManager::FATAL_ERROR_KEY,
    :expected_shipping => CheckoutManager::FATAL_ERROR_KEY,
    :expected_total_price => CheckoutManager::FATAL_ERROR_KEY,
    :expected_tax => CheckoutManager::FATAL_ERROR_KEY,
    :user_zip_code => CheckoutManager::FATAL_ERROR_KEY,
    :user_email_address => CheckoutManager::FATAL_ERROR_KEY,
    :user_address_1 => CheckoutManager::RETRIABLE_ERROR_KEY,
    :user_city => CheckoutManager::RETRIABLE_ERROR_KEY,
    :user_first_name => CheckoutManager::RETRIABLE_ERROR_KEY,
    :user_last_name => CheckoutManager::RETRIABLE_ERROR_KEY,
    :user_phone => CheckoutManager::RETRIABLE_ERROR_KEY,
    :user_state => CheckoutManager::RETRIABLE_ERROR_KEY,
    :credit_card_type => CheckoutManager::RETRIABLE_ERROR_KEY,
    :credit_card_num => CheckoutManager::RETRIABLE_ERROR_KEY,
    :credit_card_holder_name => CheckoutManager::RETRIABLE_ERROR_KEY,
    :credit_card_month => CheckoutManager::RETRIABLE_ERROR_KEY,
    :credit_card_year => CheckoutManager::RETRIABLE_ERROR_KEY,
    :credit_card_ccv => CheckoutManager::RETRIABLE_ERROR_KEY,

    :billing_zip_code => CheckoutManager::RETRIABLE_ERROR_KEY,
    :billing_email_address => CheckoutManager::RETRIABLE_ERROR_KEY,
    :billing_address_1 => CheckoutManager::RETRIABLE_ERROR_KEY,
    :billing_address_2 => CheckoutManager::RETRIABLE_ERROR_KEY,
    :billing_address_3 => CheckoutManager::RETRIABLE_ERROR_KEY,
    :billing_city => CheckoutManager::RETRIABLE_ERROR_KEY,
    :billing_first_name => CheckoutManager::RETRIABLE_ERROR_KEY,
    :billing_last_name => CheckoutManager::RETRIABLE_ERROR_KEY,
    :billing_middle_name => CheckoutManager::RETRIABLE_ERROR_KEY,
    :billing_phone => CheckoutManager::RETRIABLE_ERROR_KEY,
    :billing_state => CheckoutManager::RETRIABLE_ERROR_KEY,
    :billing_country => CheckoutManager::RETRIABLE_ERROR_KEY,
    
  }

  VARIABLES_TO_ERRORS.sort_by{|x| x.first.to_s }.each do |variable_to_nullify,expected_result|
    to_exec = Proc.new{
      new_options = @options.merge(variable_to_nullify.to_sym => nil)
      @manager = Saksfifthavenue.new(new_options)
      result = @manager.checkout
      assert_equal expected_result, result[:success_flag]
    }
    self.send(:define_method,"test_missing_#{variable_to_nullify}_raises_correct_error", &to_exec)
    break
  end

end
