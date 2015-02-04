module FetcherInstance

  attr_accessor :agent, :scc_scraper, :request_time

  def initialize
    @agent = self.agent
    @scc_scraper = nil
  end

  def log
    @log ||= self.class.log
  end

  def i18n_version
    @i18n_version ||= self.class.i18n_version
  end

  #left from the original single threaded
  def scrape_categories(options = {}) # :nodoc:
    if self.class.category_scrapers
      self.class.category_scrapers.inject([]){|cats,scraper| cats + scraper.scrape(options)}
    end
  end

  def scrape_sccs(options) # :nodoc:
    sccs_scrape_single_item(options)
    if options[:test]
      pp options[:item]
    elsif options[:items]
      options[:items].each do |item|
        apply_coupons(item,options[:coupons])
        options[:item] = item
        check_item(options)
      end
    else
      apply_coupons(options[:item],options[:coupons])
      check_item(options)
    end
  end

  def apply_coupons(item,coupons)
    if coupons && item.valid_full_price?
      applicable_coupons = coupons.select{|c| c.applies_to?(item)}
      if applicable_coupons.any?
        best_coupon = applicable_coupons.sort_by{|c| c.new_price_would_be(item)}.last
        best_coupon.apply_discount!(item)
      end
    end
  end

  def check_item(options)
    begin
      options[:item].product_image.resize_to_max
    rescue => e
    end

    if is_valid_item?(options[:item],options)
      options[:output_queue] << options[:item]
      options[:processed_item_counter].increment
    else
      options[:failed_item_counter].increment
    end
  end

  def is_valid_item?(item,options={}) # necessary for making sure post-sccs item is valid for output.
    return false if is_forbidden_brand_item?(item,options)
    item.scc && !item.scc.empty? && item.valid? && item.on_sale?
  end

  def is_forbidden_brand_item?(item,options)
    forbidden_brands = options[:forbidden_brands][item.dept] rescue []
    forbidden_brands.include?(item.brand_bm)
  end

  def sccs_scrape_single_item(options)
    @scc_scraper ||= SCCScraper.initialize_scraper(self.class, self.class.sccs_scraper_type,{},&self.class.sccs_def)
    begin
      temp_result = @scc_scraper.scrape(:item => options[:item])
      if temp_result.is_a?(Hash)
        options[:items] = temp_result[:all_items]
      else
        options[:item].scc = temp_result
      end
    rescue Exception => e
      log.error(e.to_s)
      log.error(e.backtrace.join("\n"))
    end
    @scc_scraper.agent.back! if @scc_scraper && @scc_scraper.agent
  end

  def get_categories(more_files=[]) # :nodoc:
    category_files = self.class.populate_category_file_paths(more_files.push(nil))
    
    CategoryGenerator.load_yaml_from_file(category_files)
  end

  def get_forbidden_brand_bms(fetcher_name) # :nodoc:
    forbidden_brand_file = File.join(FetcherHelperMethods.dir_path(fetcher_name), "#{fetcher_name}_forbidden_brands.#{self.class.i18n_version}.yml")
    forbidden_brand_file = File.join(FetcherHelperMethods.dir_path(fetcher_name), "#{fetcher_name}_forbidden_brands.yml") unless File.exist?(forbidden_brand_file)
    unless File.exist?(forbidden_brand_file)
      return {:womens=>[],:mens=>[],:girls=>[],:boys=>[]}
    end
    extract_brand_bms(YAML.load_file(forbidden_brand_file))
  end

  def extract_brand_bms(brand_name_hash)
    result = {:womens=>[],:mens=>[],:girls=>[],:boys=>[]}
    brand_name_hash.each do |dept,brand_list|
      brand_list.each do |brand|
        result[dept].push(Brand.get_best_matching_brand_bm(dept, brand))
        result[dept].uniq!
        result[dept].compact!
      end
    end
    result
  end



end