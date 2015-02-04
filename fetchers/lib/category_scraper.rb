$:.unshift File.join(File.dirname(__FILE__), 'data')

require 'scraper'
require 'category'
require 'category_parse_agent'
require 'condition_set'
require 'simple_condition_set'
require 'clothing_type_matcher'

class CategoryScraper < Scraper
  attr_accessor :agent
  attr_writer :name_attr, :agent
  attr_accessor :category_path, :brand
  ALWAYS_MATCH_REGEX = //
  NEVER_MATCH_REGEX = /^$/

  class CategoryScraperException < StandardError; end;
  class NoCategoryDefinitionGiven < CategoryScraperException; end;
  class BlockAndSelectorBothDefined < CategoryScraperException; end;

  def initialize(fetcher_class,options={}, &definition) # :nodoc
    raise NoCategoryDefinitionGiven if !block_given? && options[:selector].nil?
    raise BlockAndSelectorBothDefined if block_given? && options[:selector]

    @fetcher_class = fetcher_class
    
    @agent = CategoryParseAgent.new(fetcher_class)

    unless options.empty?
      @main_url = options[:main_url]
      @start_url = options[:start_url]
      if options[:auth_user]
        @agent.auth(options[:auth_user], options[:auth_passwd])
      end
      @department = options[:department]
      @category_path = options[:category_path].is_a?(Array) ? options[:category_path] : [options[:category_path]].compact
      testing if options[:testing]
    end

    if options[:selector]
      @conditions = SimpleConditionSet.new(options)
    else
      self.instance_eval(&definition)
    end

    @ignored ||= NEVER_MATCH_REGEX
    @only ||= ALWAYS_MATCH_REGEX
    @embed_for ||= ALWAYS_MATCH_REGEX
    @categories = []
    @main_url ||= ""
  end

  def scrape(options = {}) # :nodoc
    skip = options[:skip]
    @categories = []
    unless skip
      url = complete_href(@start_url || @main_url)
      unless @agent.go_to(url)
        raise "Could not follow url: #{url}"
      end
    end

    links = @agent.links(@conditions)
    if @excluded_link_indexes
      links = links.select{|x| !@excluded_link_indexes.include?(links.index(x))}
    end

    @fetcher_class.log.debug "links = #{links.inspect}"
    return @categories unless links.size > 0
    links.each do |link|
      begin
        @agent.click! link
      rescue
        @fetcher_class.log.warn "category_scraper.rb: problem following link\n#{link}"
        next
      end

      is_lowest_level = true

      cat_name = @agent.get_attr_from_link(link, @name_attr).strip
      orig_url = complete_href(@agent.get_attr_from_link(link, :href))
      # Phyo updated this to pass in "cat_name" info for debug
      use_url = @transformer ? @transformer.call(cat_name, orig_url) : @agent.agent.page.uri.to_s
      new_cat = Category.new(cat_name,use_url)

      # seed with
      new_cat.category_path.concat @category_path
      new_cat.category_path << new_cat.name unless new_cat.category_path.include?(new_cat.name)
      
      # if the category fetcher is returning nil url, we ignore the category
      new_cat.ignored = (use_url.nil? || new_cat.name =~ @ignored || !(new_cat.name =~ @only))
      new_cat.dept = @department || new_cat.guess_dept_from_url
      new_cat.clothing_type = ClothingTypeMatcher.determine_clothing_type_sym(cat_name, new_cat.dept) if new_cat.dept
      new_cat.brand = @brand

      # as in 'item_scraper', we need to modify some attributes of the category
      if @post_processor
        new_cat = @post_processor.call(new_cat)
      end

      if @embedded && cat_name =~ @embed_for && !new_cat.ignored
        @embedded.agent = @agent
        categories_from_embedded = @embedded.scrape({:skip => true})
        if categories_from_embedded
          categories_from_embedded.map{|cat|
            cat.dept ||= new_cat.dept
            cat.category_path = new_cat.category_path + cat.category_path
          }
        end
        unless categories_from_embedded.nil? || categories_from_embedded.size == 0
          current_cats = @categories.map{|x| x.url}
          # cats with already existing urls are excluded from adding
          add_categories(categories_from_embedded.select{|x| !current_cats.include?(x.url)})
          is_lowest_level = false
        end
      end
      if is_lowest_level
        @categories << new_cat unless @categories.include? new_cat
      end
      @agent.back!
    end
    @categories
  end


  def add_categories(categories_from_embedded)
    @categories.concat(categories_from_embedded)
  end

  # specifies the URL on which to find categories

  def start_url(url)
    @start_url = url
  end

  # specifies the specific brand for that category

  def brand_string(str)
    @brand = str
  end

  # specifies a regular expression used to ignore categories if the name matches the specified regular
  # expression

  def ignore(regex)
    @ignored = regex
  end

  # specifies a regular expression to select only categories whose names match

  def only(regex)
    @only = regex
  end

  # specifies the link to be excluded in scraping in order of appearance from top to bottom
  def exclude_links(*array)
    @excluded_link_indexes = array
  end

  def name(name_attr=nil, &block)
    @name_attr = name_attr

    if block_given?
      @name_attr = ConditionSet.new &block
    end
  end

  def is(element)
    @conditions = ConditionSet.new(:element => element){}
  end

  def get_name_from(name_attr)
    @name_attr = name_attr
  end

  # used to specify subcategories.  see Fetcher.categories
  def categories(options=nil, &definition)
    if options
      if options[:for]
        @embed_for = options[:for]
      end
    end
    
    @embedded = CategoryScraper.new @fetcher_class,{:main_url => @main_url}, &definition
  end

  def ancestor(options=nil, &block)
    raise "Incompatible with simple condition" if @conditions.is_a? SimpleConditionSet
    @conditions ||= ConditionSet.new(:element => "a"){}
    @conditions.ancestor(options, &block)
  end

  def with(hash)
    hash.each do |attr, value|
      add_condition(attr.to_s, value)
    end
  end

  # provide a custom block to transform a category url --
  # the block should return the transformed url
  #
  # Example:
  #  transform do |name, url|
  #    if url =~ /categoryId=/
  #      cat_id = /categoryId=(\d+)/.match(url)[1]
  #      "http://www.charlotterusse.com/family/index.jsp?totalProductsCount=1000&pageType=category&categoryId=#{cat_id}&clickid=header_new_button&view=all"
  #    else
  #      url
  #    end
  #  end

  def transform(options=nil, &block)
    @transformer = block
  end

  def manual_clothing_type_match(options=nil, &block)
    @manual_clothing_type_match = block
  end

  def post_process(&block)
    @post_processor = block
  end

private
  def add_condition(attr, value)
    raise "Incompatible with simple condition" if @conditions && @conditions.is_a?(SimpleConditionSet)
    @conditions ||= ConditionSet.new(:element => "a"){}
    @conditions.add_condition attr, value
  end

  def method_missing(method_name, *args)
    parts = method_name.to_s.split("_")
    super.method_missing(method_name, *args) unless parts.size > 1
    if parts[0] == "with"
      add_condition(parts[1], args[0])
    else
      super.method_missing(method_name, *args)
    end
  end

end
