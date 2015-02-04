
require File.dirname(__FILE__) + '/html_logger'

class ItemHtmlLogger < HtmlLogger

  def <<(item)
    super <<-OUTPUT
    <div id="item_#{item.vendor_key}" style="border: 3px black solid;"><a href="#{item.product_url}" ><b>#{item.description}</b><img src="#{item.product_image.url}" /></a></div><br /><br />

OUTPUT
  end
  
end
