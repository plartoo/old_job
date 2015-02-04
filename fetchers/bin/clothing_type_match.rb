#!/usr/bin/env ruby
## Usage: $ ruby clothing_type_match.rb (us/uk optional) < input_file

require 'rubygems'
require 'ruby-debug'
i18n_version = ARGV[0] || 'us'
require File.dirname(__FILE__) + "/../lib/data/clothing_type_patterns/clothing_type_patterns_#{i18n_version}"


OUTPUT_FILE = ARGV[1] || 'clothing_type_analysis.txt'
CLOTHING_TYPES = YAML.load_file(File.join(File.dirname(__FILE__)+"/../config/common/common_clothing_types.yml"))

@patterns = {
  :mens => ClothingTypePatternsUs::MensPatterns.concat(ClothingTypePatternsUs::CommonPatterns),
  :womens => ClothingTypePatternsUs::WomensPatterns.concat(ClothingTypePatternsUs::CommonPatterns),
  :boys => ClothingTypePatternsUs::BoysPatterns.concat(ClothingTypePatternsUs::CommonPatterns),
  :girls => ClothingTypePatternsUs::GirlsPatterns.concat(ClothingTypePatternsUs::CommonPatterns),
}

fo = File.open(OUTPUT_FILE,'w')

STDIN.read.split("\n").each do |d|
  @every_matched_patterns = {:mens=>[],:womens=>[],:boys=>[],:girls=>[]}
  @match_found = false

  @patterns.each do |dept, patterns|
    first_seen = false
    patterns.each do |pattern_and_clothing_type|
      pattern = pattern_and_clothing_type.first
      clth_type = pattern_and_clothing_type.last

      if d.match(pattern) && first_seen.eql?(false)
        fo.write "#{d}\t#{d.match(pattern)[0]}\t#{dept}\t#{CLOTHING_TYPES[clth_type][:bm]}\t"
        first_seen = true
        @match_found = true
      elsif d.match(pattern) && first_seen.eql?(true)
        @every_matched_patterns[dept].push(CLOTHING_TYPES[clth_type][:bm])
        @match_found = true
      end

    end

    @every_matched_patterns[dept].uniq.each{|x| fo.write "#{x} "}
    fo.write "\n"
  end

  unless @match_found
    fo.puts "#{d}\tNO MATCH FOUND"
  end
end

fo.close


