require 'rubygems'
require 'ruby-debug'
#usuk={
#'40'=>'24','42'=>'26','44'=>'28','46'=>'30','48'=>'32','50'=>'34','52'=>'36','54'=>'38','56'=>'40','58'=>'42'
#}

#us = ['24','26','28','30','32','34','36','38','40','42']
#uk = ['40','42','44','46','48','50','52','54','56','58']

#uk.each do |uk1|
#  uk.each do |uk2|
#    puts "\'#{uk1}/#{uk2}\'=>\'#{usuk[uk1]}X#{usuk[uk2]}\',"
#  end
#end

#28/S=>28 etc
#File.open('source.log','r').each{|l|
#  if l =~ /\d+X\d+/
#    m = l.match(/(\d+)X(\d+)/)
#    if m[2].to_i < 32
#      puts "'#{m[1]}/S'=>#{l.strip}\,"
#    elsif m[2].to_i == 32
#      puts "'#{m[1]}/R'=>#{l.strip}\,"
#    else
#      puts "'#{m[1]}/L'=>#{l.strip}\,"    
#    end
#  end
#}

File.open('source.log','r').each{|l|
  if l =~ /\d+X\d+/
    m = l.match(/(\d+)X(\d+)/)
      puts "'#{m[1]}/#{m[2]}'=>#{l.strip}\,"
   else
      puts l
   end
}