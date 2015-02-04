require 'rubygems'
require 'ruby-debug'

resultFile = ARGV[0]
puts "\n\nProcessing #{resultFile}\n\n"

#VALID ITEM COUNT(Current page)::::0
#VALID ITEM COUNT(Current category: Men's Liners & Socks)::::0
#INVALID ITEM COUNT(Current category: Men's Liners & Socks)::::35
#TOTAL VALID ITEM COUNT(For current fetcher)::::817
#TOTAL ITEM COUNT(For current fetcher)::::11831

f = File.open(resultFile,'r').each{ |line|

  if line =~ /^(IN)?VALID ITEM/ || line =~ /^TOTAL/
    puts line
  end
  if line =~ /^TOTAL ITEM COUNT/
    puts "\n\n"
  end
}
