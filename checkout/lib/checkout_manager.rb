require 'detail_fetcher'

module Checkout
  class CheckoutManager

    attr_accessor :retailer, :manager_class, :logger

    SUCCESS_FLAG = :success
    HTML_LOGGING_FOLDER = File.join(File.expand_path(File.dirname(__FILE__)), '..', 'log', 'html_log_data')

    include DetailFetcher

    def initialize(options, log=Logger.new)
      handle_variables(options)
      @logger = log
      @html_log_file_name = "#{@checkout_id}.html"
    end

    def fetch_details(product_url, vendor_key)
      log_if_slow("do_fetch_details") do
        do_fetch_details(product_url, vendor_key)
      end
    end

    def run(task)
      method_name = "do_#{task}"
      log_if_slow(method_name) do
        send(method_name)
      end
    end

    ############################################# private methods below #############################################
    private

    def handle_variables(options)
      options.each do |k,v|
        self.instance_variable_set("@#{k}",v)
      end

      @options = options
    end

    def unloggables
      @unloggables ||= compute_unloggable_values
    end

    def compute_unloggable_values
      common_fields = [@credit_card_num, @credit_card_month, @credit_card_year, @credit_card_ccv]
      (common_fields + additional_unloggable_values).compact
    end

    # could pull this out into CheckoutUtils, but we want to keep it as a module
    def split_phone_number_in_three(phone_str_with_dash)
      # assuming the user enters 10-digit phone num with or without dash
      phone_num_without_dash = phone_str_with_dash.delete("-")
      unless phone_num_without_dash.size == 10
        raise_retriable(
          {:split_phone_number_in_three => "Phone Number is not 10 digit as expected"},
          {:parameters_used => phone_str_with_dash}
        )
      end
      parts = phone_num_without_dash.match(/^(\d{3})(\d{3})(\d{4})/i)
      [parts[1],parts[2],parts[3]]
    end

    def errors_for_unexpected(actual, expected, desc)
      if expected.match(/#{actual}/i)
        {}
      else
        {desc.to_sym => "#{desc} doesn't match. Expected: #{expected} but got #{actual}"}
      end
    end

    def assert_critical_order_info_is_not_nil(keys_to_check, data)
      errors = {}
      keys_to_check.each do |k|
        unless data[k]
          errors.merge!({k => "#{k} is missing!!"})
        end
      end

      raise_fatal(errors) if errors.any?
    end

    def assert_variable_exists(var, msg)
      unless var
        raise_fatal({:assert_variable_exists => msg})
      end
    end

    # returns a non-positive value
    def calculate_discount(total, costs)
      discount = total - costs.reduce(&:+)
      raise_fatal({:discount => "total cost exceeds sum of line totals/items"},
                  {:parameters_used => {:total => total, :costs => costs}}) if discount > 0
      discount
    end

    DEFAULT_TIME_LIMIT = 10

    def time_limit(name)
      read_value("time_limit_for_#{name}", true) rescue DEFAULT_TIME_LIMIT
    end

    # return the 'name' method's value, or the constant 'NAME'
    # raise exception if neither method nor constant defined, and 'required' is true
    def read_value(name, required)
      send(name.to_sym) rescue self.class.const_get(name.upcase.to_sym)
    rescue
      required ? raise : nil
    end

    def log_if_slow(task)
      expected = time_limit(task)
      start = Time.now
      yield
    ensure
      actual = Time.now - start
      if actual > expected
        logger.error("#{task} for #{self.class} took too long: #{actual} secs. expected response within #{expected} secs")
      end
    end

    def raise_retriable(errors_hash, other_params={})
      raise RetriableError.build(errors_hash, unloggables, other_params)
    end

    def raise_fatal(errors_hash, other_params={})
      raise FatalError.build(errors_hash, unloggables, other_params.merge({:html_log_file_name => @html_log_file_name}))
    end

    def raise_out_of_stock(errors_hash, other_params={})
      raise OutOfStockError.build(errors_hash, unloggables, other_params)
    end

  end
end
