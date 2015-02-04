require 'yaml'
require 'configuration'

class SitewideCoupon # :nodoc:
  
  def initialize(arg_hash)
    @options = arg_hash
  end

  def apply_discount!(item)
    if applies_to?(item)
      item.notice =  item.notice.nil? ? @options["message"] : @options["message"] +  " " + item.notice
      
      item.sale_price = new_price_would_be(item)
    end
  end

  def new_price_would_be(item)
    # 0 = default to current_price, 1 = original, 2 = sale
    price_to_modify = [
      item.current_price, item.original_price, item.sale_price
    ][ @options["discount_which_price"].to_i ].to_f

    return if item.sale_price.nil? && @options["discount_which_price"].to_i.eql?(2)

    get_new_sale_price( price_to_modify )
  end

  def is_full_priced_items_only?
    # 1 => full price items only
    @options["item_restriction"] == 1
  end

  def applies_to_full_price_item?
    # 0 => all items
    # 1 => full price items only
    @options["item_restriction"] == 0 || @options["item_restriction"] == 1
  end

  def check_price_range(item)
    # range type 1 = Percent, 2 = Amount
    if @options["range_type"] == 1
      current_percent_off = (item.original_price.to_f - item.sale_price.to_f)/item.original_price.to_f
      if @options["min_range"]
        return false unless current_percent_off >= @options["min_range"].to_f
      end
      if @options["max_range"]
        return false unless current_percent_off <= @options["max_range"].to_f
      end
    elsif @options["range_type"] == 2
      # 0 = whichever is lower, 1 = original price, 2 = sale price
      price_to_check = [
        item.current_price, item.original_price, item.sale_price
      ][ @options["range_of_which_price"].to_i ].to_f

      if @options["min_range"]
        return false unless price_to_check >= @options["min_range"].to_f
      end
      if @options["max_range"]
        return false unless price_to_check <= @options["max_range"].to_f
      end
    end
    
    true
  end

  def applies_to?(item)
    if @options[:brands]
      return false unless valid_brand?(item)
    end

    if @options[:clothing_types]
      return false unless valid_clothing_type?(item)
    end

    return false unless check_price_range(item)
      
    # 0 = both,  1 = original only and 2 = sale only
    return false if @options["item_restriction"] == 1 && item.on_sale?
    return false if @options["item_restriction"] == 2 && !item.on_sale?

    true
  end
  def valid_brand?(item)
    has_brand = @options[:brands].include?({:bm => item.brand_bm, :dept_bm => item.department_bm})
    !(has_brand && @options["exclude_brands"] || !has_brand && !@options["exclude_brands"])
  end
  def valid_clothing_type?(item)
    has_clothing_type = @options[:clothing_types].include?({:bm => item.clothing_type_bm, :dept_bm => item.department_bm})
    !(has_clothing_type && @options["exclude_department_clothing_types"] ||
      !has_clothing_type && !@options["exclude_department_clothing_types"])
  end

  def valid_on?(date)
    @options['start_date'] <= date && date <= @options['end_date']
  end

  def self.load_from_sitm(feed_path, date)
    coupons = YAML.load(`#{Configuration["coupon_tool_cmd"].gsub(/FEED_PATH/, feed_path.to_s)}`) rescue nil
    return unless coupons
    sitewide_coupons = configure_coupon(coupons)
    sitewide_coupons.select do |coupon|
      coupon.valid_on?(date)
    end
  end

  private

  def self.configure_coupon (coupons)
    coupons.map do |db_hash|
      options = db_hash.dup
      if db_hash[:brands].size > 0
        options[:brands] = []
        db_hash[:brands].each do |brand|
          options[:brands].push :bm => brand[:brand]["bitmask_id"], :dept_bm => brand[:department]["bitmask_id"]
        end
      end
      if db_hash[:clothing_types].size > 0
        options[:clothing_types] = []
        db_hash[:clothing_types].each do |clothing_type|
          options[:clothing_types].push :bm => clothing_type[:clothing_type]["bitmask_id"], :dept_bm => clothing_type[:department]["bitmask_id"]
        end
      end
      SitewideCoupon.new(options)
    end
  end

  def get_new_sale_price(price)
    if @options["discount_type"] == 1
      price = (price * (1 - @options["amount"].to_f)).to_s
    else
      price = (price - @options["amount"].to_f).to_s
    end
      "%0.2f" % price
  end

end
