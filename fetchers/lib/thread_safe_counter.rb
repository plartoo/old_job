class ThreadSafeCounter

  def initialize
    @counter = Queue.new
  end

  def increment
    @counter << nil
    self.value
  end

  def decrement
    @counter.pop if @counter.size > 0
    self.value
  end

  def value
    @counter.size
  end

  def to_s
    value.to_s
  end

end