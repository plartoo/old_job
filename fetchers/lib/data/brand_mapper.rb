require 'trie'

class BrandMapper # :nodoc:

  def initialize
    @trie = Trie.new
  end

  def add_brand(brand_name, brand)
    @trie.push(brand_name, brand)
  end

  def get_best_matching_brand(value)
    key = @trie.longest_prefix(value)
    @trie.get(key)
  end

end
