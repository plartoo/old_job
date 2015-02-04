$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'rubygems'
require 'mechanize'
#require 'mechanize_extension'
require 'ruby-debug'


def cart_item
  t = 1
  'hellow' if false
end
cart_item
debugger

def retry_while(options = {}, &block)
    opts = {:tries => 3}.merge(options)

    key, value, retries = opts[:key], opts[:value], opts[:tries]

    result = {}
    loop do
      retries -= 1
      result = block.call
      break if (retries == 0 || result[key] != value)
    end
    result
  end

  hash = {'response_code' => 'out_of_stock_error'}
  hoosh = {'response_code' => 'no error'}

  i = 0
  e = retry_while({:key => 'response_code', :value => 'out_of_stock_error'}) do
    i += 1
    hoosh
    if i <= 3
      hoosh
    else
      hoosh
    end
  end

    debugger
agent = Mechanize.new
pg = agent.get('file:///home/phyo/workspace/checkout/macys_trial/checkout-webflow_final.htm')

debugger


REPLACEMENT_STR = "X-REPLACED-X"
      def mangle(data, word)
        if data.is_a?(String)
         data.gsub(/\b#{word}\b/i, REPLACEMENT_STR)
        elsif data.is_a?(Hash)
          result = {}
          data.each do |k,v|
            result[k] = (v == word ? REPLACEMENT_STR : v)
          end
          result
        elsif data.is_a?(Array)
          data.map{|v| v == word ? REPLACEMENT_STR : v}
        else
          raise TypeError
        end
      end

      def hide_sensitive_data(parameters, words_to_censor)
        words_to_censor.inject(parameters) do |p, w|
          mangle(p, w)
        end
      end

      CC_NUM = '123456'
      CC_MONTH = 'November'
      CC_YEAR = '2011'
      CC_CCV = '255'

      censor_words_1 = [CC_NUM, CC_MONTH, CC_YEAR, CC_CCV]
      test_params_1 =         {

          'newCreditCard.creditCardExpiryNum' => CC_NUM,
          'newCreditCard.creditCardExpiryMonth' => CC_MONTH,
          'newCreditCard.creditCardExpiryYear' => CC_YEAR,
          'newCreditCard.creditCardExpiryCCV' => CC_CCV,

          'promoCodes[0]' => 'abcd',
          'promoCodes[1]' => '2011 255',
        }

      pp "#{hide_sensitive_data(test_params_1, censor_words_1).inspect}"
      censor_words_2 = [CC_NUM, CC_MONTH, CC_YEAR, CC_CCV]
      test_params_2 = "hello world #{CC_NUM} 2011255 #{CC_NUM}"
      pp "#{hide_sensitive_data(test_params_2, censor_words_2).inspect}"

      censor_words_3 = [CC_NUM, CC_MONTH, CC_YEAR, CC_CCV]
      test_params_3 = [CC_NUM, "hello world", CC_MONTH]
      pp "#{hide_sensitive_data(test_params_3, censor_words_3).inspect}"
      
#@step = 0
#def write_out_page(message,page)
#  @step += 1
#  File.open('woohoo.html','a'){|f|
#    f << "\n##################################################\n#{Time.now}\n#{@step+=1}-----#{message}\n\n"
#    f << page.content
#  }
#end
#
#@url = "http://www1.bloomingdales.com/catalog/product/index.ognc?ID=455052&CategoryID=17885"
#@cookie_file = "rootyroot.yml"
#@testing = 1
#@agent = Mechanize.ew
#
#
#def extract_category_id_and_product_id
#  @category_id = @url.match(/CategoryID=(\d+)/)[1] rescue nil
#  @id = @url.match(/\?ID=(\d+)/)[1] rescue nil
#end
#
#def load_cookies_to_agent
#  @agent.cookie_jar.load_from_hash(@cookies)
#end
#
#def fetch_order_data
#    extract_category_id_and_product_id
#    if @testing.any? && File.exists?(@cookie_file)
#      @cookies = YAML.load_file(@cookie_file)
#    else
#      raise "Cookie file may not exist"
#    end
#    load_cookies_to_agent
#    header = {"Cookie" => cookie_string}
#
#    debugger
#
#    proceed_to_checkout_from_item_detail_page(header)
#    write_out_page("fetcher_order_data => Step 1", @page)
#    proceed_to_checkout_from_shopping_bag_page
#    write_out_page("fetcher_order_data => Step 2", @page)
#    proceed_to_checkout_from_shopping_bag_shipping_information_page
#    write_out_page("fetcher_order_data => Step 3", @page)
#
#    fill_out_shipping_address_info_and_proceed
#    write_out_page("fetcher_order_data => Step 4", @page)
#    select_shipping_option_and_proceed
#    write_out_page("fetcher_order_data => Step 5", @page)
#    fill_out_billing_address_info_and_proceed
#    write_out_page("fetcher_order_data => Step 6", @page)
#
#    return fetch_order_total_data
#end
#
