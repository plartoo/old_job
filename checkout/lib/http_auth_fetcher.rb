require 'net/http'
require 'net/https'

class HttpAuthFetcher

  def initialize(options={})
    @options = {
      :username=>nil,
      :password=>nil,
      :read_timeout => 60
    }.merge(options)
  end

  def fetch(url, parms={}, redirect_limit=10)
    raise ArgumentError, 'HTTP redirect too deep' if redirect_limit == 0
    url = URI.parse(url)

    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = @options[:read_timeout]
    if url.scheme == "https"
      http.use_ssl = true
    end

    if parms.empty?
      url_with_query = url.query ? url.path + "?" + url.query : url.path
      req = Net::HTTP::Get.new(url_with_query)
    else
      req = Net::HTTP::Post.new(url.path)
      req.body = parms.to_query
      req.content_type = 'application/x-www-form-urlencoded'
    end

    if @options[:username] && @options[:password]
      req.basic_auth @options[:username], @options[:password]
    end

    res = http.start{|http| http.request(req)}

    case res
      when Net::HTTPSuccess
        res.body
      when Net::HTTPRedirection
        fetch(res['location'], {}, redirect_limit - 1)
      when Net::HTTPNotFound
        raise Net::HTTPError.new(res.code, res.code_type)
      when Net::HTTPInternalServerError
        raise Net::HTTPServerException.new(res.code, res.code_type)
      else
        res.error!
    end
  end

end
