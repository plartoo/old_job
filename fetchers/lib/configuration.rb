# To change this template, choose Tools | Templates
# and open the template in the editor.

class Configuration
  ENVIRONMENT = ENV['ENVIRONMENT'] || ENV['RAILS_ENV'] || 'development'
  
  @@application = "us"
  
  def self.application=(application)
    @@application = application
  end
  
  def self.application
    @@application
  end

  def self.config_dir
    File.join(File.dirname(__FILE__), "..", "config/#{application}")
  end
  
  def self.[](key)
    @@config ||= YAML.load_file(File.join(config_dir, "..", "common", "configuration.yml"))[self.application.to_sym].merge(YAML.load_file(File.join(config_dir,"configuration.yml"))[ ENVIRONMENT ])
    @@config[key]
  end

  def self.fetchers_dir
    File.join(File.dirname(__FILE__), "..", "fetchers")
  end
end
