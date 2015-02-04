class ThreadSafeHash

  attr_accessor :data

  def initialize
    Thread.critical = true
    @data = {}
  ensure
    Thread.critical = false
  end

  def []=(key,data)
    Thread.critical = true
    @data[key] = data
  ensure
    Thread.critical = false
  end

  def [](key)
    Thread.critical = true
    @data[key]
  ensure
    Thread.critical = false
  end

  def has_key?(key)
    Thread.critical = true
    !@data[key].nil?
  ensure
    Thread.critical = false
  end

  def keys
    Thread.critical = true
    @data.keys
  ensure
    Thread.critical = false
  end

  def values
    Thread.critical = true
    @data.values
  ensure
    Thread.critical = false
  end

  def ==(other)
    Thread.critical = true

    return false unless other.is_a?(ThreadSafeHash)
    
    @data == other.data
  ensure
    Thread.critical = false
  end

  alias_method :eql?, :==

end
