

class ClosedList

  attr_accessor :data

  def initialize
    @data = []
  end

  def << (datum)
    Thread.critical = true
    @data << datum if !self.include?(datum)
  ensure
    Thread.critical = false
  end

  def size
    @data.size
  end

  def include?(datum)
    @data.include?(datum)
  end
  
end