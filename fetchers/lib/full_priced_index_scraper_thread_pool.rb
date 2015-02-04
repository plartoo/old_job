require 'index_scraper_thread_pool'

class FullPricedIndexScraperThreadPool < IndexScraperThreadPool

  def create_item_scraper
    scraper = super

    scraper.setup!
        
    # remove pagination limit
    scraper.paginator.max_page_limit(nil)

    scraper.add_category_info_to_item = true
    scraper.exclude_duplicate_items = false
    
    scraper
  end
  
end