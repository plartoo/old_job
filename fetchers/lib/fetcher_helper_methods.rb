class FetcherHelperMethods

  def self.agent(fetcher_class) # :nodoc:
    agent = Agent.new(fetcher_class)
    agent.user_agent = "Mozilla/5.0 (Windows; U; Windows NT 6.1; de; rv:1.9.1.5) Gecko/20091102 Firefox/3.5.5"
    agent
  end

  def self.spawn_new_fetcher_instance(fetcher_class_name,fetcher_name) # :nodoc:
    fetcher_path = load_fetcher_file(fetcher_name)

    fetcher_class = Kernel.const_get(fetcher_class_name)
    fetcher_class.fetcher_name = fetcher_name
    fetcher_class.path = fetcher_path
    
    fetcher = fetcher_class.new

    fetcher
  end

  def self.load_fetcher_file(fetcher_name)
    dir_path = dir_path(fetcher_name)
    unless File.exist?(dir_path)
      raise "fetcher directory doesn't exist: #{dir_path}"
    end

    fetcher_path = File.join(dir_path, "#{fetcher_name}.rb")
    unless File.exist?(fetcher_path)
      raise "fetcher definition file doesn't exist: #{fetcher_path}"
    end

    require fetcher_path

    fetcher_path
  end

  def self.dir_path(fetcher_name) # :nodoc:
    File.join(File.dirname(__FILE__), '..', 'fetchers', fetcher_name)
  end

  def self.template # :nodoc:
    File.join(File.dirname(__FILE__), '..', 'config', 'templates', 'fetcher.txt')
  end

  def self.class_and_name(vendor_class, vendor_path = nil) # :nodoc:
    vendor_path = vendor_path || vendor_class.underscore
    [vendor_class, vendor_path]
  end

  CLASS_NAME_REGEXP = /class (\w+)/i
  def self.get_fetcher_class_name_from_name(vendor_name)
    # guess class name from vendor_name
    File.open(File.join(File.dirname(__FILE__),"..","fetchers",vendor_name,"#{vendor_name}.rb")) do |f|
      f.readlines.grep(CLASS_NAME_REGEXP).first[CLASS_NAME_REGEXP,1]
    end
  end

  def self.get_fetcher_names_from_item(item)
    fetcher_class_name = nil
    fetcher_name = item.vendor_name
    fetcher_class_name = get_fetcher_class_name_from_name(item.vendor_name)
    [fetcher_name,fetcher_class_name]
  end

end