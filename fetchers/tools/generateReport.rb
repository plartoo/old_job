#!/usr/bin/env ruby
require 'rubygems'
require 'ruby-debug'
require 'erb'

## Report set ups and category scraping related
def report_category_scraping(input)
  report = ''
  flag = 0
  name,url = nil,nil
  input.each do |line|
    return report if line.match(/fetched \d+ items from/)

    if line.match(/Starting at (.*?)$/)
      report += "Started: " + line.match(/Starting at (.*?)$/)[1]
    elsif line.match(/loaded (\d+) coupon/)
      report += "\nLoaded coupon(s): #{line.match(/loaded (\d+) coupon/)}"
    elsif line.match(/INVALID ITEM=>/) || line.match(/.*?fetched \d+ items from \'.*?$/)
      flag = 3
    elsif line.match(/category scraper is ignored/)
      report += "\n" + line.match(/(category.*?)$/)[1] + "\n"
    elsif line.match(/found \d+ new categories/)
      report += "\n\nNum. of new categories found: #{line.match(/found (\d+) new categories/)[1]}"
      report += "\nList of new categories found:\n"
      flag = 1
    elsif line.match(/found \d+ missing categories/)
      report += "\n\nNum. of missing categories (on the cat file but no longer seen on the site): #{line.match(/found (\d+) missing categories/)[1]}"
      report += "\nList of missing categories:\n"
      flag = 2
    elsif flag == 1
      name = line.match(/\:name\: (.*?)$/)[1] rescue nil if !name
      url = line.match(/str\: (http\:.*?)$/)[1] rescue nil if !url
      if name && url
        report += url + "\t" + name + "\n"
        name,url = nil,nil
      end
    elsif flag == 2
      name = line.match(/\:name\: (.*?)$/)[1] rescue nil if !name
      url = line.match(/(http\:.*?)$/)[1] rescue nil if !url
      if name && url
        report += url + "\t" + name + "\n"
        name,url = nil,nil
      end
    elsif flag == 3
      return report
    end
  end
end

def report_item_index_page_scraping(input)
  flag = 0
  url = nil
  hash = {:brand_name => [],:brand_mapping_failed => [],:no_department => [],
    :no_orig_price => [], :image_error => [], :no_product_url => [],
    :no_vendor_key => []
  }
  report = ''
  input.each do |line|
    break if line.match(/INVALID SIZE/)

    if line.match(/INVALID ITEM/)
      flag = 1
    elsif line.match(/<=====/)
      flag = 0
      url = nil
    elsif flag != 0 && line.match(/URL:/)
      url = line.match(/URL: (.*?$)/)[1] rescue nil
    elsif flag != 0 && line.match(/No \w+/)
#      options[:fetcher_log].info("\tNo Brand recognized: #{item.brand}") if (item.brand_bm.nil? && !item.brand.nil?)
#      options[:fetcher_log].info("\tNo Brand mapped: #{item.description}") if (item.brand_bm.nil? && item.brand.nil?)
#      options[:fetcher_log].info("\tNo department info.") if (item.dept.nil?)
#      options[:fetcher_log].info("\tNo original price.") if (item.original_price.nil?)
#      options[:fetcher_log].info("\tNo product image.") if !@product_image || !@product_image.valid?
#      options[:fetcher_log].info("\tNo product url.") if (item.product_url.nil?)
#      options[:fetcher_log].info("\tNo vendor key.") if (item.vendor_key.nil?)

      hash[:brand_name].push line.match(/recognized: (.*?)$/)[1] if line.match(/recognized/)
      hash[:brand_mapping_failed].push line.match(/mapped: (.*?)$/)[1] if line.match(/mapped/)
      hash[:no_department].push url if line.match(/department info/)
      hash[:no_orig_price].push url if line.match(/original price/)
      hash[:image_error].push url if line.match(/product image/)
      hash[:no_product_url].push url if line.match(/product url/)
      hash[:no_vendor_key].push url if line.match(/vendor key/)
    elsif line.match(/fetched \d+ items in total/)
      report += "Number of invalid items from item_index_page_scraping because of.."
      report += "\nBrand not being recognized: #{hash[:brand_name].uniq.size} and are:"
      report += "\n\t\t#{hash[:brand_name].uniq.inspect}"
      report += "\nBrand not being mapped correctly: #{hash[:brand_mapping_failed].uniq.size}"
      #report += "\n\t\t#{hash[:brand_mapping_failed].uniq.inspect}"
      report += "\nNo department info available: #{hash[:no_department].uniq.size}"
      #report += "\n\t\t#{hash[:no_department].uniq.inspect}"
      report += "\nNo original price info available: #{hash[:no_orig_price].uniq.size}"
      #report += "\n\t\t#{hash[:no_orig_price].uniq.inspect}"
      report += "\nNo product image available (could be caused by not recognizing brands): #{hash[:image_error].uniq.size}"
      #report += "\n\t\t#{hash[:image_error].uniq.inspect}"
      report += "\nNo product url available: #{hash[:no_product_url].uniq.size}"
      #report += "\n\t\t#{hash[:no_product_url].uniq.inspect}"
      report += "\nNo vendor key available: #{hash[:no_vendor_key].uniq.size}"
      #report += "\n\t\t#{hash[:no_vendor_key].uniq.inspect}"
      return report
    end
  end

end

def match_size_errors(line)
  index_in_hash = 0
  @VALUE_DEPT_GROUP_BM_REGEX = /.*value:(.+?)\sis.*dept:(.*?),\sclothing_type:\s\{:group=>.*?(\w+).*?:bm=>.*?(\d+)/
  @VALUE_DEPT_BM_GROUP_REGEX = /.*value:(.+?)\sis.*dept:(.*?),\sclothing_type:\s\{:bm=>.*?(\d+).*?:group=>.*?(\w+)/
  m = @VALUE_DEPT_GROUP_BM_REGEX.match(line)
  m, index_in_hash = @VALUE_DEPT_BM_GROUP_REGEX.match(line), 1 if !m
  return m,index_in_hash
end

def summarize_size_errors_from_hash(size_hash)
  output = "\n"
  size_hash.keys.each{|k1|
    output += k1 + "\n"
    size_hash[k1].keys.each{|k2|
      output += "\n\t\t" + k2.to_s + "\n"
      size_hash[k1][k2].keys.sort.each {|k3|
      output += "\n\t\t\t\t"+ k3.to_s + "\n"
      url_limit = 0
        size_hash[k1][k2][k3].uniq.sort.each{|k4|
          if url_limit < 4
            k4 = 'unavailable' if k4.empty?
            output +=  "\n\t\t\t\t\t\t" + k4.to_s + "\n"
            url_limit += 1
          end
        }
      }
    }
  }
  return output
end

def store_size_errors_in_hash(line,size_error_info,index,size_hash)
  link = line.match(/URL:\s(.*)/)
  if !link.nil? & !size_error_info.nil?
    url_bucket_in_size_hash = size_hash[size_error_info[2].strip][size_error_info[3+index].to_s.strip][size_error_info[1].to_s.strip]
    # if the size_value is not registered in the hash, create a bucket for urls to store
    if url_bucket_in_size_hash.empty? || (size_hash[size_error_info[2].strip][size_error_info[3+index].to_s.strip].nil?)
      size_hash[size_error_info[2].strip][size_error_info[3+index].to_s.strip][size_error_info[1].to_s.strip] = []
      size_hash[size_error_info[2].strip][size_error_info[3+index].to_s.strip][size_error_info[1].to_s.strip].push(link[1]).uniq
    else
      url_bucket_in_size_hash.push(link[1]).uniq
    end
    size_error_info = nil
  end
  return size_hash
end

## I can refactor this method
def report_invalid_sizes(input)
  size_hash = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc)}
  size_error_info = nil
  index = 0
  input.each do |line|
    break if line.match(/SUMMARY of sccs scraping/)
    if line =~ /INVALID\sSIZE:/
      #size_error_info stores 'size_value','dept_name' and 'clothing_type_group'/'clothing_type_bm' in that order
      size_error_info,index = match_size_errors(line)
    end
    if line =~ /URL:/
      size_hash = store_size_errors_in_hash(line,size_error_info,index,size_hash)
    end
  end
  summarize_size_errors_from_hash(size_hash)
end

def report_yield_and_time(input)
  flag = 0
  report = "\nSCCS scraping yield: "
  input.each do |line|
    if line.match(/Number of items with successful SCCS scraping: \d+/)
      report += line.match(/(\d+ out of \d+.*?$)/)[1] + "\n"
    elsif line.match(/wrote \d+ items to file/)
      report += line.match(/(wrote \d+ items.*?$)/)[1] + "\n"
      flag = 1
    elsif flag == 1
      report += line
    end
  end
  return report
end

def report_errors(input)
  ## record the first seven lines of error message
  error = ''
  report = []
  line_count = 0
  input.each do |line|
    if line.match(/\[ERROR\] [^\#]/)
      error += line.match(/\[ERROR\] (.*)$/)[1] + "\n" rescue nil
    elsif line.match(/\:\d+\:in/) && line_count < 4 && !error.empty?
      error += line
      line_count += 1
    elsif line_count == 4
      report.push error unless report.include?(error)
      error = ''
      line_count = 0
    end
  end
  return report
end

def report_summary(output, input, fetcher_name)
  ## we read the file twice--for error and regular reporting--because errors
  ## can be found anywhere in the file and could make regular reporting to be wrong
  
  output.write("***************#{fetcher_name}***************\n")
  output.write("ERROR SUMMARY\n---------------\n")
  errors = report_errors(input)
  output.write("Num. of unique errors: #{errors.size}")
  output.write("\nError list:\n#{errors.to_s}")
end

def report_details(output, input, fetcher_name)
  report = <<-EOS


Category Scraping
-----------------
<%= report_category_scraping(input) %>

Item Index Page Scraping
------------------------
<%= report_item_index_page_scraping(input) %>

SCC Scraping
-------------
List of Invalid Sizes:
(department)\t(name)\t(clothing_type_group)\t\t(sample_url)
<%= report_invalid_sizes(input) %>


Yield and time fetcher spent
----------------------------
<%= report_yield_and_time(input) %>
***************End Of <%= fetcher_name %>*********************

EOS

  output.write ERB.new(report).result(binding)
end

def log_file_list(date, dir)
  date = date.strftime("%y%m%d") if date.is_a? Date
  Dir.glob(File.join(dir, "*_#{date}.log"))
end

date = ENV['DATE'] || Date.today
log_files = log_file_list(date, ARGV[0]||Dir.pwd).sort
REPORT_FILE_NAME = "fetcher_report_#{date}"


output = ARGV[0]=="stdout" ? STDOUT : File.open(REPORT_FILE_NAME, 'a+')
output.write("\n\t\tFetcher Report for #{date}\n\n")
log_files.each do |fetcher_file_name|
  puts "Handling log file #{fetcher_file_name}"
  fetcher_name = fetcher_file_name.match(/(.*?_.*?)_/)[1]
  File.open(fetcher_file_name, 'r') do |input|
    report_summary(output, input, fetcher_name)
  end
  File.open(fetcher_file_name, 'r') do |input|
    report_details(output, input, fetcher_name)
  end
end
output.write("\n\n\t\tEnd of Fetcher Report for #{date}")
output.close

