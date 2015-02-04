class CategoryGenerator

  def initialize(categories, fetcher)
    @categories = categories
    @fetcher = fetcher
    @vendor = @fetcher.class.fetcher_name
  end
  
  def to_yaml(tag_line = "Category clothing_type overrides item clothing type")
    yaml_str = hashify(@categories).to_yaml
<<-EOS
##{tag_line}
#{yaml_str}
EOS
  end

  def self.generate_hash(categories, vendor)
    hsh = {:active => [], :ignored => [], :vendor => vendor}
    categories.each do |cat|
      hsh[cat.ignored ? :ignored : :active] << cat
    end
    hsh
  end
    
  def generate_hash(categories)
    hsh = {:active => [], :ignored => [], :vendor => @vendor}
    categories.each do |cat|
      hsh[cat.ignored ? :ignored : :active] << cat
    end
    hsh
  end

  def hashify(categories)
    hash = {:active => [], :ignored => [], :vendor => @vendor}
    categories.each do |cat|
      hash[cat.ignored ? :ignored : :active] << cat.to_hash
    end
    hash
  end

  def generate_yaml(full_price=false,path = nil,tag_line = nil)
    full_price_label = full_price ? "full_price_" : nil

    path ||= File.join(FetcherHelperMethods.dir_path(@vendor), "#{@vendor}_#{full_price_label}categories.#{@fetcher.i18n_version}.yml")
    if File.exist?(path)
      FileUtils.mv(path, path + '.old')
      puts "put existing categories file in .old"
    end

    File.open(path, "w+") do |f|
      f << to_yaml(tag_line)
    end
    puts "wrote categories to file"
  end

  def self.generate_diff(cats_from_file, cats_from_fetch)
    cats_from_file = sort_category_list(cats_from_file)
    cats_from_fetch = sort_category_list(cats_from_fetch)

    new = []
    missing = Array.new(cats_from_file)
    cats_from_fetch.each do |fe_cat|
      fi_cat = nil
      missing.each do |i|
        if i == fe_cat
          fi_cat = i
          missing.delete(i)
          break
        end
      end

      if fi_cat.nil?
        new << fe_cat
      end
    end
    [new, missing]
  end

  def self.sort_category_list(cats)
    cats.sort do |a, b|
      a.url <=> b.url
    end
  end

  def self.load_yaml_from_file(filenames)
    categories = {:active=>[]}
    filenames.each do |filename|
      File.open(filename) do |f|
        self.load_yaml(f).each do |key,val|
          if key.eql?(:active)
            categories[key].concat val
          else
            categories[key] ||= val
          end
        end
      end
    end
    categories
  end

  def self.load_yaml(yaml)
    categories = YAML::load(yaml)
    categories[:active].map! do |cat|
      Category.load_from_hash(cat)
    end
    categories[:ignored].map! do |cat|
      Category.load_from_hash(cat)
    end
    categories
  end

  def self.arrayhash2cathash(hsh)
    hsh[:active].map! {|c| Category.new *c}
    hsh[:ignored].map! {|c| Category.new *c}
    hsh
  end

end
