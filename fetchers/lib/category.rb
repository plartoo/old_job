class Category
  attr_accessor :name, :url, :ignored, :clothing_type, :dept, :item_elements, :brand
  attr_accessor :clothing_type, :ignored, :dept, :paginator_iterations, :prioritized
  attr_accessor :total_item_for_current_category, :total_valid_item_for_current_category
  attr_accessor :category_path

  def initialize(name, url, ignored=false, clothing_type=nil, dept=nil, brand=nil)
    @url = url
    @name = name
    @ignored = ignored
    @clothing_type = clothing_type
    @dept = dept
    @item_elements = []
    @brand = brand
    @paginator_iterations = 0
    @total_item_for_current_category = 0
    @total_valid_item_for_current_category = 0
    @prioritized = false

    @category_path = []
  end

  PATTERNS = [
    [/women/i, :womens],
    [/men/i, :mens],
    [/girl/i, :girls],
    [/boy/i, :boys]
  ]

  def guess_dept_from_url
    PATTERNS.select{|x| url.match(x[0])}.first[1] rescue nil
  end

  def to_hash
    data = {:name => @name,
      :url => @url,
      :ignored => @ignored,
      :clothing_type => @clothing_type,
      :dept => @dept || guess_dept_from_url,
      :category_path => @category_path,
    }
    if @brand
      data.merge!({:brand => @brand})
    end
    data
  end

  def to_yaml
    to_hash.to_yaml
  end

  def is_valid?
    !@name.nil? &&
    !@url.nil? &&
    !@clothing_type.nil? &&
#    @clothing_types.size > 0 &&
    !@dept.nil?
  end

  def self.load_from_hash(hash)
    url = hash[:url]
    name = hash[:name]
    ignored = hash[:ignored]
    clothing_type = hash[:clothing_type]
    dept = hash[:dept]
    brand = hash[:brand]
    category = Category.new(name, url, ignored, clothing_type, dept, brand)
    category.category_path = hash[:category_path]
    category
  end

  def ==(other)
    other.is_a?(Category) &&
      other.name == @name &&
      other.url == @url &&
      other.ignored == @ignored
  end
  
  def prioritized?
    @prioritized
  end

  alias_method :eql?, :==

end
