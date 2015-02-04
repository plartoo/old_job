# used with items definitions in fetchers of the form:
# 
# items do
#   define_custom_item_list do |page|
#    ...
#   end
#   item_list do |item,page|
#    ...
#   end
# end
# 

class CustomItemList
  attr_accessor :item_enumerator_block
  def initialize(options={}, &block)
    @item_list_block = block;
  end
  
  def produce_list(*args)
    begin
      @items = @item_list_block.call(*args)
    rescue Exception => e
      puts "Exception in define_custom_item_list: #{e.message}"
      raise e
    end
  end
  
  def each(&block)
    @items.each(&block)
  end
  
  def set_item_data(item,item_data,agent)
    begin
      @item_enumerator_block.call(item,item_data,agent)
    rescue Exception => e
      puts "Exception in define_custom_item_list_iterator: #{e.message}"
      raise e
    end
  end
  
  def from_detail_page
    false
  end
  
end