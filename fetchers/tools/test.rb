require 'rubygems'
require 'ruby-debug'
require 'open-uri'
require 'mechanize'

#def test
#  a = [1,2,3,4]
#  b = ['a','b','c']
#  return a,b
#end
#
#c,d = test
#
#puts "#{c.inspect}"
#puts "#{d.inspect}"

#o = {:item => '1'}#{:vendor_bm => 1, :item => '1'}
#def test(options)
#  item = options.delete(:vendor_bm)
#  puts item
#  puts "#{options.inspect}"
#end
#test(o)
#puts "#{ENV["ahah"].inspect}"

url = 'http://www.spartoo.co.uk/shoes-women.php'
agent = Mechanize.new
page = agent.get(url)
#puts page.content
#my_ip = open("http://www.frenchconnection.com") { |f| /([0-9]{1,3}\.){3}[0-9]{1,3}/.match(f.read)[0].to_a[0] }
##my_ip = open("http://www.frenchconnection.com")
#
#puts "#{my_ip.inspect}"
