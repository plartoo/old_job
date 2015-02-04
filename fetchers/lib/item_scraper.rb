$:.unshift File.join(File.dirname(__FILE__), 'data')

require 'scraper'
require 'item'
require 'item_parse_agent'
require 'condition_set'
require 'image_condition_set'
require 'custom_condition_set'
require 'paginator'
require 'brand'
require 'sitewide_coupon'
require 'custom_item_list'
require 'thread_safe_hash'

class ItemScraper < Scraper
  attr_accessor :from_detail_page, :agent, :paginator_iterations
  attr_accessor :paginator, :add_category_info_to_item, :exclude_duplicate_items
  attr_accessor :vendor_key_pattern, :fetcher_class

  cattr_accessor :past_items_cat_data

  @@past_items_cat_data = ThreadSafeHash.new

  def initialize(fetcher_class,options=nil, &definition) # :nodoc:
    raise "no item definition" unless block_given?

    @fetcher_class = fetcher_class

    Utils.i18n_version = @fetcher_class.i18n_version
    
    if options
      main_url(options[:main_url], true)
      @brand = options[:brand]
      @from_detail_page = options[:from_detail_page]
      if options[:auth_user]
        @auth = [options[:auth_user], options[:auth_passwd]]
      end
      @uncategorized_clothing_type_logger = options[:uncategorized_clothing_type_logger]
      @add_category_info_to_item = options[:add_category_info_to_item]
    else
      @from_detail_page = false
    end
    @definition = definition
    @duplicate = false
    @exclude_duplicate_items = true
  end
  
  def scrape(options)
    options[:vendor_key_closed_list] ||= []
    cat = options[:cat]
    cat.prioritized = false
    new_items_in_this_page = false
    coupons = options[:coupons]
    scrape_full_price_items = options[:full_price_items] ? options[:full_price_items] : false
    Item.validate_sale_price = !scrape_full_price_items

    setup!

#    @items ||= {}
    url = complete_href(cat.url)

    @fetcher_class.log.debug cat.inspect
    
    @fetcher_class.log.info("\nitem_scraper.rb: Scraping category: #{cat.name}")

    nexted_so_far = 0
    job_finished = true
    @paginator.each(@agent, self, url) do |url|
      if nexted_so_far < cat.paginator_iterations
        nexted_so_far += 1
        next
      end
      job_finished = false
      @fetcher_class.log.info "item_scraper.rb: url-> #{url}"

      unless @agent.go_to(url)
        cat.item_elements = []
        job_finished = true
        break
      end
     
      # this is needed as in the case of "Lord And Taylor" fetcher where
      # pagination for view all must be called by "POST" instead of "GET" method
      if @modify_item_parse_agent
        @modify_item_parse_agent.call(@agent, url)
      end
      #detect cases where pagination returns the same list of items despite different page numbers
      # in url
#      if @agent.base_nodes
#        if @agent.base_nodes.select{|x| cat.item_elements.include?(x.to_s)}.length == @agent.base_nodes.length
#          cat.item_elements = []
#          if @agent.base_nodes.length == 0
#            @fetcher_class.log.info "\nitem_scraper.rb: This is the end of pagination for this category."
#          else
#            @fetcher_class.log.info "\nitem_scraper.rb: These items are already seen."
#          end
#          @fetcher_class.log.info "Move on to the next category.\n********************\n"
#          job_finished = true
#          break
#        else
#          cat.item_elements += @agent.base_nodes.map{|x| x.to_s}
#        end
#      end
      item_count = 0

      coupons_for_full_priced_items = coupons ? coupons.select{|c| c.applies_to_full_price_item?} : []

      @agent.each(@parts, cat) do |item|
        begin
          next if item.nil? || (!@testing && item.description.nil?)

          if @pre_processor
            item = @pre_processor.call(item,cat)
          end

          handle_item!(item,cat)

          if @post_processor
            item = @post_processor.call(item,cat)
          end

          options[:item_scraper_total_counter].increment
          cat.total_item_for_current_category += 1

          let_this_item_pass = coupons_for_full_priced_items.any?

          if item.valid? || let_this_item_pass
            cat.prioritized = true
#            if @items.has_key?(item.vendor_key)
            if @exclude_duplicate_items && options[:vendor_key_closed_list].include?(item.vendor_key)
              @fetcher_class.log.warn("item_scraper.rb: item.vendor_key \"#{item.vendor_key}\" is already in the hash (You may want to check if your vendor_key is unique)")

              if @duplicate
                @fetcher_class.log.info "item_scraper.rb: These items are already seen. Finishing category.\n"
                job_finished = true
                break #this category is done
              end
              
              options[:data_sender].send("#{@fetcher_class.data_sender_short_name}_dup_fail",1) if options[:data_sender]

              options[:data_sender].send("#{@fetcher_class.data_sender_short_name}_scr_fail",1) if options[:data_sender]
              options[:data_sender].send("aggregate_scr_fail",1) if options[:data_sender]

              next #don't continue with this item.
            end

            unless options[:vendor_key_closed_list].include?(item.vendor_key)
              new_items_in_this_page = true
            end

            # don't check discount if full price items are also scraped
            unless scrape_full_price_items
              next if (item.sale_price.to_f / item.original_price.to_f > 0.8) && !let_this_item_pass
            end

            cat.total_valid_item_for_current_category += 1
            item_count += 1
            item.product_url = complete_href(item.product_url)
            item.product_image.url = complete_href(item.product_image.url)

            save_category_data!(item.vendor_key,cat)

            add_category_data_to_item!(item)

            options[:vendor_key_closed_list] << item.vendor_key
            

            options[:data_sender].send("#{@fetcher_class.data_sender_short_name}_scr_suc",1) if options[:data_sender]
            options[:data_sender].send("aggregate_scr_suc",1) if options[:data_sender]

            # poll to push, since we are using sized queue, but should break with timelimit
            until (options[:item_sccs_queue] << {:type => FetcherThreadPool::ITEM_FOR_SCCS, :work => item})
              break if options[:time_to_stop] && (Time.now.to_i > options[:time_to_stop])
              sleep(1)
            end
          end

          if options[:data_sender]
            if item.brand_bm.nil? && item.brand.nil?
              options[:data_sender].send("#{@fetcher_class.data_sender_short_name}_brn_fail",1)
            end
            if item.clothing_type.nil?
              options[:data_sender].send("#{@fetcher_class.data_sender_short_name}_cat_fail",1)
            end
          end
        rescue Exception => e

          if item.clothing_type.nil? && @uncategorized_clothing_type_logger
            @uncategorized_clothing_type_logger << item
          end

          @fetcher_class.log.error(e.to_s)
          @fetcher_class.log.error(e.backtrace.join("\n"))

          options[:data_sender].send("#{@fetcher_class.data_sender_short_name}_scr_fail",1) if options[:data_sender]
          options[:data_sender].send("aggregate_scr_fail",1) if options[:data_sender]
          
          next
        end
      end # item iteration ends

      item_count.times{ options[:item_scraper_valid_counter].increment }
      @fetcher_class.log.info "VALID ITEM COUNT(Current page)::::" + item_count.to_s
      @fetcher_class.log.info "VALID ITEM COUNT(Current category: #{cat.name})::::" + cat.total_valid_item_for_current_category.to_s
      @fetcher_class.log.info "INVALID ITEM COUNT(Current category: #{cat.name})::::" + (cat.total_item_for_current_category - cat.total_valid_item_for_current_category).to_s
      @fetcher_class.log.info "TOTAL VALID ITEM COUNT(For current fetcher)::::#{options[:item_scraper_valid_counter]}"
      @fetcher_class.log.info "TOTAL ITEM COUNT(For current fetcher)::::#{options[:item_scraper_total_counter]}"
      @agent.back!

      cat.paginator_iterations += 1
      break
    end

    if !new_items_in_this_page
      job_finished = true
    end
    #### Modify this line when we know it's time to stop paginating
    [cat.total_valid_item_for_current_category, (!job_finished ? cat : nil) ]
  end

  def save_category_data!(vendor_key,category)
    return unless @add_category_info_to_item
    
    @@past_items_cat_data[vendor_key] ||= []
    @@past_items_cat_data[vendor_key] << {:url => category.url, :name => category.name, :path => category.category_path}
  end

  def add_category_data_to_item!(item)
    return unless @add_category_info_to_item

    item.category_data = @@past_items_cat_data[item.vendor_key] || []
  end

  def item_block(block_structure=nil, &block)
    if block_given?
      @agent.structure = ConditionSet.new &block
    elsif block_structure.is_a?(Hash)
      @agent.structure = SimpleConditionSet.new(block_structure)
    elsif block_structure.is_a?(String)
      @agent.structure = SimpleConditionSet.new(:selector => block_structure)
    else
      raise "item block was not a recognized condition set type"
    end
  end

  def vendor_key(pattern)
    @vendor_key_pattern = pattern
  end

  def pagination(&block)
    @paginator = Paginator.new(@fetcher_class.log, &block)
  end

  def post_process(&block)
    @post_processor = block
  end

  def modify_item_parse_agent(&block)
    @modify_item_parse_agent = block
  end

  def pre_process(&block)
    @pre_processor = block
  end

  def currency(curr)
    @currency = curr
  end

  def stop_pagination_if_duplicate_item_seen
    @duplicate = true
  end

  def default_currency
    Configuration[:default_currency]
  end

  def conditions
    @parts
  end

  def evaluate_definition
    @parts ||= {}
    begin
      self.instance_eval(&@definition)
    rescue Exception => e
      @fetcher_class.log.info "Invalid items definition: #{e}"
      raise e
    end
  end

  def setup!
    return if @agent
    @agent = ItemParseAgent.new(@fetcher_class)

    if @auth
      @agent.auth(*@auth)
    end

    @parts = {}

    evaluate_definition

    @main_url ||= ""
    @paginator ||= Paginator.new @fetcher_class.log
  end
  
  private

  def handle_item!(item, cat)
    item.dept ||= cat.dept
    
    item.vendor_name = @fetcher_class.fetcher_name rescue nil

    if !cat.clothing_type.nil?
      item.clothing_type = ClothingType[cat.clothing_type, item.dept]
    else
      ClothingTypeMatcher.i18n_version = @fetcher_class.i18n_version
      item.clothing_type ||= ClothingTypeMatcher.determine_clothing_type(@fetcher_class,item)
    end

    if item.clothing_type.nil? && @uncategorized_clothing_type_logger
      @uncategorized_clothing_type_logger << item
    end

    if @testing
      item.brand_bm ||= 0
    else
      bm = Brand.get_best_matching_brand_bm(item.dept, @brand || item.brand || cat.brand || item.description)
      item.brand_bm ||= bm
    end
    if item.brand && !item.description.index(item.brand)
      item.description = item.brand + ' ' + item.description
    end
    item.currency ||= @currency || default_currency
    item.vendor_key ||= @vendor_key_pattern.match(item.product_url)[1] rescue nil # this is kind of horrible; extract to class?
  end

  def define_custom_item_list_iterator(&block)
    raise "must use define_custom_item_list before define_custom_item_list_iterator" unless @parts["custom_item_list"]
    @parts["custom_item_list"].item_enumerator_block = block
  end

  def add_condition(part, condition_set)
    @parts["#{part}"] = condition_set
  end

  def define_custom_item_list(&block)
    add_condition(:custom_item_list, CustomItemList.new(nil, &block))
  end

  # ==See add_part
  def description(options = {}, &block)
    add_part(:description, options, &block)
  end
  # ==See add_part
  def description_custom(options = {}, &block)
    add_part(:description_custom, options, &block)
  end

  # ==See add_part
  def original_price(options = {}, &block)
    add_part(:original_price, options, &block)
  end
  # ==See add_part
  def original_price_custom(options = {}, &block)
    add_part(:original_price_custom, options, &block)
  end

  # ==See add_part
  def sale_price(options = {}, &block)
    add_part(:sale_price, options, &block)
  end
  # ==See add_part
  def sale_price_custom(options = {}, &block)
    add_part(:sale_price_custom, options, &block)
  end

  # ==See add_part
  def product_url(options = {}, &block)
    add_part(:product_url, options, &block)
  end
  # ==See add_part
  def product_url_custom(options = {}, &block)
    add_part(:product_url_custom, options, &block)
  end

  def product_image(options=nil, &block)
    add_condition(:product_image, ImageConditionSet.new(options, &block))
  end
  # ==See add_part
  # :direct_value is always set to true for product image custom
  def product_image_custom(options = {}, &block)
    options = options.merge(:direct_value => true)
    add_part(:product_image_custom, options, &block)
  end

  # ==See add_part
  def brand(options = {}, &block)
    add_part(:brand, options, &block)
  end
  # ==See add_part
  def brand_custom(options = {}, &block)
    add_part(:brand_custom, options, &block)
  end

  # ==See add_part
  def notice(options = {}, &block)
    add_part(:notice, options, &block)
  end
  # ==See add_part
  def notice_custom(options = {}, &block)
    add_part(:notice_custom, options, &block)
  end

  # ==Adds parts to an item scraper
  # Called from method "part_name"
  #   description do
  #     is 'a'
  #   end
  # or
  #    description :selector => 'CSS3 Selector'
  def add_part(part_name, options, &block)
    if  part_name.to_s =~ /_custom/
      part = part_name.to_s.gsub('_custom', '')
      add_condition(part, CustomConditionSet.new(options, &block))
    elsif options[:selector]
      add_condition(part_name.to_s, SimpleConditionSet.new(options))
    else
      add_condition(part_name.to_s, ConditionSet.new(options, &block))
    end
  end

end
