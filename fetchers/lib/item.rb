$:.unshift File.join(File.dirname(__FILE__), '..')
$:.unshift File.join(File.dirname(__FILE__), 'data')

require 'item_image'
require 'department'
require 'digest/md5'

class Item
  attr_accessor :description, :brand_bm, :department_bm, :clothing_type_bm, :clothing_type, :product_url, :product_image, :original_price, :sale_price, :scc, :dept, :clothing_type, :vendor_key, :brand, :notice, :data
  attr_writer :description, :product_url, :product_image, :vendor_key, :department_bm, :scc, :brand_bm, :brand, :notice
  attr_accessor :currency, :internal_data, :vendor_name, :category_data
  attr_accessor :extended_description, :additional_images, :related_vendor_keys, :scc_label_value_pairings

  PRICE_PATTERN = /.*?\$?((\d|,)+\.*\d*).*?/

  ItemException = Class.new(Exception)
  InvalidSCCException = Class.new(ItemException)
  InvalidVendorKey = Class.new(ItemException)

  @@validate_sale_price = true

  def initialize(*args)
    @description = args[0]
    @product_url = args[1]
    @product_image = args[2]
    @original_price = args[3].nil? ? args[3] : Utils.get_price_str(args[3])
    @sale_price = args[4].nil? ? args[4] : Utils.get_price_str(args[4])
    @notice = args[5]
    @internal_data = nil
    @vendor_name = nil
    @extended_description = {}
    @additional_images = []
    @related_vendor_keys = []
    @scc_label_value_pairings = []
  end

  def on_sale?
    !@sale_price.nil? && @sale_price.size > 0
  end

  def valid_full_price?
    return false unless valid_attributes?
    return false unless @clothing_type_bm
    return false unless @brand_bm
    true
  end

  def valid_attributes?
    return false unless @vendor_key
    return false unless @description
    return false unless @product_url
    return false unless @product_image && @product_image.valid?
    return false unless @original_price
    true
  end

  def current_price
    on_sale? ? sale_price.to_f : original_price.to_f
  end

  def self.validate_sale_price
    @@validate_sale_price
  end

  def self.validate_sale_price=(value)
    @@validate_sale_price = value
  end

  def valid?
    return false unless self.valid_full_price?
    if @@validate_sale_price
      return false unless @sale_price
    end
    true
  end

  def clothing_type=(type)
    return if type.nil?
    @clothing_type = type
    @clothing_type_bm = type[:bm]
  end

  def dept=(dept)
    @dept = dept
    @department_bm = Department[dept]
  end

  def check_price(price) # not international safe
    price = PRICE_PATTERN.match(price)
    return if price.nil?
    sprintf("%.2f", price[1].delete(',').to_f)
  end

  def original_price=(price)
    @original_price = check_price(price)
  end

  def sale_price=(price)
    @sale_price = check_price(price)
  end

  def to_yaml
    to_hash.to_yaml
  end

  def to_hash
    { :description => @description,
      :brand_bm => @brand_bm,
      :vendor_key => @vendor_key,
      :dept => @dept,
      :department_bm => @department_bm,
      :clothing_type_bm => @clothing_type_bm,
      :clothing_type => @clothing_type,
      :product_url => @product_url,
      :product_image => @product_image.to_hash,
      :dynamic => {
        :notice => @notice,
        :original_price => @original_price,
        :sale_price => @sale_price,
        :currency => @currency},
      :scc => @scc,
      :vendor_name => @vendor_name,
      :category_data => @category_data || {},
      :extended_description => @extended_description || {},
      :additional_images => @additional_images || [],
      :related_vendor_keys => @related_vendor_keys || [],
    }
  end

  def self.load_from_hash(h)
    item = Item.new
    item.description = h[:description].to_s
    item.original_price = h[:dynamic][:original_price].to_s
    item.sale_price = h[:dynamic][:sale_price].to_s
    item.brand_bm = h[:brand_bm].to_i
    item.department_bm = h[:department_bm].to_i
    item.dept = h[:dept].to_sym
    item.clothing_type = {:bm => h[:clothing_type_bm].to_i, :group => h[:clothing_type][:group].to_s}
    item.notice = h[:notice].to_s
    item.product_url = h[:product_url].to_s
    item.scc = h[:scc]
    item.vendor_key = h[:vendor_key].to_s
    item.product_image = ItemImage.new(h[:product_image][:url],h[:product_image][:width],h[:product_image][:height],h[:product_image][:buffer_width])
    item.currency = h[:dynamic][:currency]
    item.vendor_name = h[:vendor_name]
    item.category_data = h[:category_data].is_a?(Array) ? h[:category_data] : []
    item.extended_description = h[:extended_description] || {}
    item.additional_images = h[:additional_images] || []
    item.related_vendor_keys = h[:related_vendor_keys] || []
    item
  end

  def ==(other)
    equal = other.is_a?(Item) &&
      other.description == @description &&
      other.brand_bm == @brand_bm &&
      other.department_bm == @department_bm &&
      other.vendor_key == @vendor_key &&
      other.original_price == @original_price &&
      other.sale_price == @sale_price &&
      other.currency == @currency &&
      other.vendor_name == @vendor_name


    return equal unless equal

    if other.product_url && @product_url
      if other.product_url.size > @product_url.size
        equal = !other.product_url.index(@product_url).nil?
      else
        equal = !@product_url.index(other.product_url).nil?
      end
    end

    return equal unless equal

    return true if other.scc.nil? && @scc.nil?
    return false if other.scc.nil? && !@scc.nil?
    return false if !other.scc.nil? && @scc.nil?

    sorter = lambda do |a, b|
      result = a[:size_type_bm] <=> b[:size_type_bm]
      result = a[:color] <=> b[:color] if result == 0
      result = a[:size_bm] <=> b[:size_bm] if result == 0
      result
    end

    other.scc.sort(&sorter) === @scc.sort(&sorter)
  end
  
  def hash
    self.vendor_key.hash
  end

  def scc=(scc)
    raise InvalidSCCException unless valid_scc(scc)
    @scc = scc
  end
  
  # we explicitly check the class of elements that compose the scc array because these items will be 
  # serialized in YAML must be basic Ruby objects for the parsing work work correctly.
  # we'll allow empty scc to pass though because invalid sizes are returned sometimes
  # and that causes 'scc' to be [] or nil
  def valid_scc(scc) # :nodoc
    scc.nil? || scc.empty? ||
      scc.is_a?(Array) &&
        scc.map{|x| x.is_a?(Hash)}.uniq == [true] &&
          scc.map{|x| x.values.map{|y| y.is_a?(Fixnum) || y.is_a?(String)}}.flatten.uniq == [true]
  end

  def unique_id
    raise InvalidVendorKey if @vendor_key.nil?
    
    Digest::MD5.hexdigest("#{@vendor_key}#{@vendor_name}")
  end

  alias_method :eql?, :==

end
