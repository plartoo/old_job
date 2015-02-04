require 'mechanize'
require 'checkout_manager'
require 'checkout_manager_error'
require 'checkout_utils'

module Checkout
  class MechanizeCheckoutManager < CheckoutManager

    DEFAULT_USER_AGENT = "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.2.17) Gecko/20110422 Ubuntu/9.10 (karmic) Firefox/3.6.17"

    def initialize(options, log=Logger.new)
      super(options, log)

      @agent = Mechanize.new
      @agent.user_agent = DEFAULT_USER_AGENT
      @page = nil
    end

    ############################################# private methods below #############################################
    private

    def load_cookies_to_agent
      assert_cookies_exist
      cookie_jar.load_from_hash(YAML.load(@cookies))
    end

    def cookies_exist?
      @cookies && !@cookies.empty?
    end

    def assert_cookies_exist
      unless cookies_exist?
        raise_fatal({:cookies => "No cookie no purchase."})
      end
    end

    def cookie_jar
      @agent.cookie_jar
    end

    def log_html_data_for_current_page(message)
      parameters = message.delete(:parameters)
      parameters = CheckoutUtils.hide_sensitive_data(parameters, unloggables) if parameters

      FileUtils::mkdir_p(CheckoutManager::HTML_LOGGING_FOLDER)
      File.open(File.join(CheckoutManager::HTML_LOGGING_FOLDER,@html_log_file_name),"a") do |f|
        f << "<div style='text-align: left'><pre>#{Time.now}<br />#{message.to_yaml}</pre></div>"
        f << "<div style='text-align: left'><pre>parameters used:<br />#{parameters.to_yaml}</pre></div>"
        f << @page.content
      end
    end

    def agent_get(name, options={})
      must_verify = [:page_title, :custom_assert] - (options[:no_verify] || [])

      get_parameters = {
        :url => url(name),
        :headers => options[:headers]
        }

      @agent.log.debug "\n\nAGENT_GET: #{name}"
      @page = @agent.get(get_parameters)
      @agent.log.debug "@page.title: #{@page.title}"

      log_html_data_for_current_page({name => get_parameters, :parameters => options})

      assert_for(name, must_verify.include?(:custom_assert))

      title = page_title(name, must_verify.include?(:page_title))
      assert_on_page(title, get_parameters) if title
    end

    def post_and_validate(name, options={})
      must_verify = [:page_title, :custom_assert] - (options[:no_verify] || [])

      agent_post(name)
      log_html_data_for_current_page({name => url(name), :parameters => parameters(name)})

      after_post if respond_to?(:after_post)
      assert_for(name, must_verify.include?(:custom_assert))

      title = page_title(name, must_verify.include?(:page_title))
      assert_on_page(title, parameters(name)) if must_verify.include?(:page_title)
    end

    def agent_post(name)
      @agent.log.debug "\n\nAGENT_POST: #{name}"
      @page = @agent.post(url(name), parameters(name), headers(name) || {})
      @agent.log.debug "@page.title: #{@page.title}"
    end

    def assert_on_page(expected_pg_title, parameters_used=nil)
      unless @page.title.match(/#{expected_pg_title}/i)
        @agent.log.debug "\nassert_on_page_failed with: expected page title: '#{expected_pg_title}'. actual page title: '#{@page.title}'"
        raise_fatal(
          {:unexpected_page => "expected page title: '#{expected_pg_title}'. actual page title: '#{@page.title}'"},
          {:parameters_used => parameters_used}
        )
      end
    end

    def page_search_price(css_selector)
      str = @page.search(css_selector)[0].text.strip rescue nil
      CheckoutUtils.price_str_to_decimal(str)
    end

    def assert_for(name, required=true)
      assert_sym = "assert_for_#{name}".to_sym
      params = parameters(name, false)
      @agent.log.debug "assert_for_#{name}" if respond_to?(assert_sym)
      begin
        send(assert_sym, params)
      rescue ArgumentError
        send(assert_sym)
      end
    rescue NoMethodError
      required ? raise : nil
    end

    def url(name)
      @agent.log.debug "\n#{name}_url => " + read_value("#{name}_url", false).inspect
      read_value("#{name}_url", true)
    end

    def parameters(name, required=true)
      @agent.log.debug "\n#{name}_parameters => " + read_value("#{name}_parameters", false).inspect
      read_value("#{name}_parameters", required)
    end

    def headers(name, required=false)
      @agent.log.debug "\n#{name}_headers => " + read_value("#{name}_headers", false).inspect
      read_value("#{name}_headers", required)
    end

    def page_title(name, required=true)
      @agent.log.debug "\n#{name}_page_title => " + read_value("#{name}_page_title", false).inspect
      read_value("#{name}_page_title", required)
    end

    # need to raise errors when expected key is missing?
    def cookie_string(cookie_names = nil)
      cookies = cookie_names.nil? ? @agent.cookies: @agent.cookies.select{|c| cookie_names.include?(c.name)}
      cookies.collect{|k,v| "#{k}=#{v}"}.join('; ')
    end

  end
end

