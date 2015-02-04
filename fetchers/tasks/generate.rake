namespace :generate do
  desc "Generate sizes/ yaml files for specified I18N_VERSION"
  task :sizes do
    Size.generate_sizes_yml(Fetcher.setup_i18n_version(ENV['I18N_VERSION']))
  end
  
  desc "Generaite brands/ yaml files for specified I18N_VERSION"
  task :brands do
    i18n_version = ENV['I18N_VERSION'].nil? ? :us : ENV['I18N_VERSION'].to_sym
    Brand.generate_brands_yml(i18n_version)
  end
  
end
