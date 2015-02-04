
require 'rubygems'
require 'optparse'

class NoLogFileSelected < StandardError; end

def process_file(file,words)
  if file !~ /\.gz$/
    File.open(file,"r").each do |line|
      process_line(line,words)
    end
  else
    # try if it's gzipped
    lines = `zcat #{file}`
    lines.each do |line|
      process_line(line,words)
    end
  end
end
#Mon Jan 24 05:15:48 -0500 2011: [1537] [moosejaw] result: Failed to determine clothing type for Moosejaw Men's Luke Garver 1/4 Zip Lightweight Fleece
CLOTHING_TYPE_LINE = /Failed to determine clothing type for (.+)/
def process_line(line,words)
  if line =~ CLOTHING_TYPE_LINE
    matched_words = line.match(CLOTHING_TYPE_LINE)[1].split
    matched_words.each do |word|
      word = cleanse_word(word)
      return unless word
      
      words[word] ||= 0
      words[word] += 1
    end
  end
end

STOP_WORDS = ["the","in","womens","mens"]
MIN_WORD_LENGTH = 3
def cleanse_word(word)
  if word
    word.gsub!("-"," ")
  end

  if word
    word.gsub!(/[^\w\s]/,"")
  end

  if word
    word.gsub!(/\s/," ")
    word.gsub!("  "," ")
  end

  if word
    STOP_WORDS.each do |stop_word|
      if word.match(/#{stop_word}/i)
        word = nil 
        break
      end
    end
  end

  if word
    if word.to_i > 0 ||
        word.match(/[^\s]/i).nil? ||
        word.length < MIN_WORD_LENGTH

      word = nil
    end
  end
  
  word
end

SPACER = 5
def print_final_counts(words)
  sorted = words.sort_by{|x| -1 * x.last}
  longest_word = words.keys.sort_by{|x| -1 * x.size}.first
  sorted.each do |word, count|
    word_length = word.size
    spaces = longest_word.size + SPACER - word_length
    puts "#{word}#{(" " * spaces)}#{count}"
  end
end


options = {:log_file => nil}
opts = OptionParser.new do |opts|
  opts.banner = "Usage: ruby collectUnmatchedClothingTypes -l log_file \n\n"
  opts.on("-l LOG_FILE", "--log LOG_FILE", "Path to the log file to parse.") do |f|
    options[:log_file] = f
  end
end
opts.parse!(ARGV)

raise NoLogFileSelected unless options[:log_file]

words = {}
process_file(options[:log_file],words)
print_final_counts(words)
