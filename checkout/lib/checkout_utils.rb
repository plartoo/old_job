module Checkout
  class CheckoutUtils
    REPLACEMENT_STR = "X-REPLACED-X"

    def self.clean_price_str(str)
      str.gsub(/[^0-9\.]/,'') rescue nil
    end

    def self.price_str_to_decimal(str)
      self.clean_price_str(str).to_d rescue nil
    end

    def self.extract_alphabets_only(str)
      str.gsub(/[^A-Za-z]/,'') rescue nil
    end

    def self.mangle(data, word)
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

    def self.hide_sensitive_data(parameters, words_to_censor)
      raise TypeError unless words_to_censor.is_a?(Array)

      words_to_censor.inject(parameters) do |p, w|
        mangle(p, w)
      end
    end

  end
end
