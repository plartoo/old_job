class Utils

#  @@i18n_version = nil

  # === str.gsub(/[^\000-\177]/, "\s")
  def self.replace_non_ascii_with(str, replacement = '')
    str.gsub(/[^\000-\177]/, replacement)
  end

  # === string.gsub(/&amp;/, '&').delete("\n\r\t").gsub(/\s+/, ' ').strip
  def self.cleanup(str)
    str.gsub(/&amp;/, '&').delete("\n\r\t").gsub(/\s+/, ' ').strip
  end

  def self.convert_price_to_float(price_str)
    cleanse_chars = ['$',',']
    cleanse_chars.each do |char|
      price_str = price_str.delete(char)
    end
    price_str.to_f
  end

  def self.get_price_str(str)
    if I18nVersion.value.eql?('uk')
      price_pattern = /\£.*?([\d\,\.]+)/
    elsif I18nVersion.value.eql?('us')
      price_pattern = /\$.*?([\d\,\.]+)/
    end
    str.match(price_pattern)[1].delete(',') rescue nil
  end

  def self.i18n_version=(i18n_version)
    I18nVersion.i18n_version = i18n_version
  end
end
