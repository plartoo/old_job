require 'mechanize'

# monkey patch for cookie jar to load cookies from hash
class Mechanize::CookieJar
  def load_from_hash(hash)
    raise ArgumentError, "The parameter must be hash" unless hash.is_a?(Hash)
    @jar = hash
  end
end