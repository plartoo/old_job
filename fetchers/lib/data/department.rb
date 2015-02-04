$:.unshift File.join(File.dirname(__FILE__), '..')
require 'configuration'
require 'yaml'

module Department # :nodoc:

  @@departments = YAML.load_file(File.join(Configuration.config_dir, "..", "common", 'departments.yml'))

  def self.[](dept_name)
    unless @@departments.key?(dept_name)
      return nil
    end
    @@departments[dept_name]
  end

  def self.all
    @@departments.keys
  end

end
