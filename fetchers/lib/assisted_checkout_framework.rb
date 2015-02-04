require File.dirname(__FILE__)+"/fetcher_framework"
require File.dirname(__FILE__)+"/item"

class AssistedCheckoutFramework < FetcherFramework

  LOG_DIR = "log/fetch_detail"

  def run
    setup

    @scc_scraper = SCCScraper.initialize_scraper(@fetcher.class, @fetcher.class.sccs_scraper_type,{},&@fetcher.class.sccs_def)
    item = Item.new()
    item.product_url = @product_url
    item.vendor_key = @vendor_key
    @scc_scraper.class.grab_scc_label_value_pairings = true
    @scc_scraper.send(:setup!,item)

    # For assisted checkout, we were waiting too long for net/http to timeout; this will set the timeout to reasonable limit JUST for assisted checkout
    @scc_scraper.agent.agent.read_timeout = 10

    if @scc_scraper.agent.go_to(@product_url)

      FileUtils.mkdir_p(LOG_DIR)
      File.open("#{LOG_DIR}/#{Time.now.to_s(:number)}.html", "a+") do |f|
        f.write(@scc_scraper.agent.page.content)
      end

      @scc_scraper.previous_page = @scc_scraper.agent.page
      @scc_scraper.handle_scc_label_value_pairings!(item)
      item.scc_label_value_pairings
    else
      raise "Page inaccessible."
    end
  end

  private

  # don't want to use FetcherFramework's setup method
  def setup
    return if @setup_complete

    @fetcher = spawn_and_configure_fetcher

    @fetcher.log.info "Scraping detail for #{self.class}"
    # log more information later?

    @setup_complete = true
  end

end
