require File.dirname(__FILE__) + "/configuration"

class Base # :nodoc:
  
  def self.connect_active_record(application = 'us')
    application = application.to_sym
    connection_parameters = {:adapter => :mysql}.merge(YAML.load_file(File.join(self.config_dir, "/../../database.yml"))[application][:db])
    ActiveRecord::Base.establish_connection(connection_parameters)
  end

end