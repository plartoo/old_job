require 'condition_set'

class SizeMatcher
  attr_accessor :mapper

  # takes an instance of SizeMapper
  def initialize(size_mapper)
    @mapper = size_mapper
  end

  def give_me(options=nil, &block)
    @give_me = ConditionSet.new(&block)
  end

  def process(options=nil, &block)
    @process = block
  end

  # run a size and item through any specified SizeMappers
  # Delegates to the SizeMapper map instance method
  def match(size, item)
    @mapper.map(size, item)
  end

end
