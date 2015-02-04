require 'checkout_utils'

module Checkout
  class CheckoutManager

    UNKNOWN_ERROR_KEY = :unknown_error

    class CheckoutManagerError < StandardError;
      attr_accessor :errors, :parameters_used, :data, :html_log_file_name
      def self.build(errors_hash, unloggable_values, other_params={})
        obj = new()
        obj.errors = errors_hash
        unless other_params[:parameters_used].nil?
          obj.parameters_used = CheckoutUtils.hide_sensitive_data(other_params[:parameters_used], unloggable_values)
        end
        obj.data = other_params[:data] # for data returned during error
        obj.html_log_file_name = other_params[:html_log_file_name]
        obj
      end

      HASHABLE_FIELDS = [:response_code, :errors, :parameters_used, :data, :html_log_file_name]

      def to_hash
        HASHABLE_FIELDS.inject({}) do |h, key|
          h[key] = send(key)
          h
        end
      end

    end

    class RetriableError < CheckoutManagerError;
      def response_code
        :retriable_error
      end
    end

    class OutOfStockError < CheckoutManagerError;
      def response_code
        :out_of_stock_error
      end
    end

    class FatalError < CheckoutManagerError;
      def response_code
        :fatal_error
      end
      def to_hash
        super.merge({:backtrace => backtrace})
      end
    end

  end
end
