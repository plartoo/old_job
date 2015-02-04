require 'rubygems'
require 'ruby-debug'

resultFile = ARGV[0]
puts "\n\nProcessing #{resultFile}\n\n"

# Assuming a sequence of input lines like this:
#skipping item scraping and loading items directly from 100126_us.yml
#INVALID SIZE: value: 02 X 32 is not a valid size for dept: womens, clothing_type: {:bm=>"6", :group=>"bottom"} 
# URL: http://www.calvinklein.com/product/index.jsp?productId=3524892
#INVALID SIZE: value: 06 X 32 is not a valid size for dept: womens, clothing_type: {:bm=>"6", :group=>"bottom"} 
# URL: http://www.calvinklein.com/product/index.jsp?productId=3524892

a = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }

size_info = nil

f = File.open(resultFile,'r').each{ |line|

  if line =~ /INVALID\sSIZE:/
    m = /.*value:(.+?)\sis.*dept:(.*?),\sclothing_type:\s\{:bm=>.*?(\d+).*?:group=>.*?(\w+)/.match(line)#/.*value:(.+?)\sis.*dept:(.*?),\sclothing_type:\s\{:bm=>(.*?), :group=>:(\w+)\}/.match(line)
    #m = /.*value:(.+?)\sis.*dept:(.*?),\sclothing_type:\s\{:group=>:(\w+), :bm=>(.*?)\}/.match(line) if m.nil?
    if m
      size_info = m
    end
  end
    
  if line =~ /URL:/
    link = line.match(/URL:\s(.*)/)
    if !link.nil? & !size_info.nil?
      if a[size_info[2].strip][size_info[4].to_s.strip][size_info[1].to_s.strip].empty?
        a[size_info[2].strip][size_info[4].to_s.strip][size_info[1].to_s.strip] = []
        a[size_info[2].strip][size_info[4].to_s.strip][size_info[1].to_s.strip].push(link[1]).uniq
      elsif a[size_info[2].strip][size_info[4].to_s.strip].nil?
        a[size_info[2].strip][size_info[4].to_s.strip][size_info[1].to_s.strip] = []
        a[size_info[2].strip][size_info[4].to_s.strip][size_info[1].to_s.strip].push(link[1]).uniq
      else
        a[size_info[2].strip][size_info[4].to_s.strip][size_info[1].to_s.strip].push(link[1]).uniq
      end
      size_info = nil
    end
  end
}

a.keys.each{|k1|
  puts k1
  a[k1].keys.each{|k2|
    puts "\t"+k2.to_s
    a[k1][k2].keys.sort.each {|k3|
    puts "\t\t"+k3.to_s
    count = 0
      a[k1][k2][k3].uniq.sort.each{|k4|
        if count < 4
          k4='unavailable' if k4.empty?
          puts "\t\t\t"+k4.to_s
          count += 1
        end
      }
    }
  }
}
