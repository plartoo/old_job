require 'rubygems'
require 'yaml'
require 'ruby-debug'

resultFile = ARGV[0]
puts "\n\nProcessing #{resultFile}\n\n"

result = {}
@key = nil

f = File.open(resultFile,'r').each do |line|

  unless line.match(/^\-/)

    @key = line.strip.gsub(/\:$/,'')
  else
    result[@key] = line.match(/\-.*?(\d+)/)[1] rescue nil
    @key = nil
  end
end

outfilename = "#{resultFile.gsub(/(.*?)\..*/,'\\1.yml')}"
fo = File.open(outfilename,'w')
fo.puts result.to_yaml
fo.close

puts "\n\nWrote results to #{outfilename}"