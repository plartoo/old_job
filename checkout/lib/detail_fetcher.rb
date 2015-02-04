require 'checkout_manager_error'

module DetailFetcher
  PATH_TO_FETCHERS = ENV['FETCHERS_HOME'] || File.expand_path(File.join(File.dirname(__FILE__),"..","..","fetchers"))
  $:.unshift File.join(PATH_TO_FETCHERS,"lib")
  require 'assisted_checkout_framework'

  ### for now, let it be "us"
  I18N_VERSION = "us"

  def no_description?(fetched_data)
    fetched_data[:full_description].nil? || fetched_data[:full_description].empty?
  end

  def out_of_stock?(fetched_data)
    begin
      fetched_data[:out_of_stock] || fetched_data[:size_colors].nil? || fetched_data[:size_colors].empty?
    rescue StandardError => e
      raise_fatal({:fetch_details => "DetailFetcher.out_of_stock? #{e.inspect}"},
                   {:data => fetched_data})
    end
  end

  def do_fetch_details(product_url, vendor_key)
    fetcher_class_name = self.manager_class.to_s[/::(.*)/,1]
    fetcher_name = self.retailer
    framework_setup_options = {
                                :fetcher_class_name => fetcher_class_name,
                                :fetcher_name => fetcher_name,
                                :i18n_version => I18N_VERSION,
                                :product_url => product_url,
                                :vendor_key => vendor_key,
                                }

    Mechanize.log.debug "\n\nFetchDetails for #{fetcher_name} => #{product_url}"
    fetched_data = AssistedCheckoutFramework.new(framework_setup_options).run

    if out_of_stock?(fetched_data)
      raise_out_of_stock({:out_of_stock => "Item seems to be out of stock."},
                          {:parameters_used => framework_setup_options, :data => fetched_data})
    end

    if no_description?(fetched_data)
      raise_fatal({:fetch_details => "Detail page fetched_data isn't as expected/empty."},
                  {:parameters_used => framework_setup_options, :data => fetched_data})
    end

    fetched_data.merge({:response_code => Checkout::CheckoutManager::SUCCESS_FLAG})
  end

end
