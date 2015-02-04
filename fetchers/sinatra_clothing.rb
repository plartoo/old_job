require 'rubygems'
require 'sinatra'
require 'yaml'
require 'thread'

INPUT_FILE = ARGV.select{|x| x =~ /INPUT/}.first.match(/INPUT=(.*)/)[1] rescue "item_training_data.txt"
OUTPUT_FILE = ARGV.select{|x| x =~ /OUTPUT/}.first.match(/OUTPUT=(.*)/)[1] rescue "clothing_training_data.txt"
clothing_types_file = ARGV.select{|x| x =~ /TYPES/}.first.match(/TYPES=(.*)/)[1] rescue "/usr/local/fetchers/current/config/common/common_clothing_types.yml"

raise "No input file defined" if INPUT_FILE.nil? || !File.exist?(INPUT_FILE)

clothing_types = YAML::load_file(clothing_types_file)
CLOTHING_TYPES = clothing_types.reject{|x,y| y[:group].nil? }

`touch #{OUTPUT_FILE}`

data = Queue.new

get '/' do
  show_question(data)
end

get '/save_item' do
  show_question(data)
end

get '/reload_queue' do
  reload(data)
end

def reload(data)
  item = []
  temp_data = []
  File.open(INPUT_FILE,'r') do |f|
    f.lines.each do |line|
      line = line.strip
      if line =~ /#############/
        temp_data << item
        item = []
        next
      end
      item << line
    end
  end

  temp_data.shuffle!

  temp_data.each{|single_item| data << {:description => single_item[0].strip,
                                 :product_url => single_item[1].strip,
                                 :img_url => single_item[2].strip,
                                 :clothing_type => single_item[3].strip,
                                 :cats => single_item[4..-1].join(" ").strip,
                                 :attempted_clothing_types => [],}
                                 }
  
  "Data has been reloaded. <a href='/'>Start categorizing</a>"
end

post '/save_item' do
  item_hash = {:description => params[:description],
               :product_url => params[:product_url],
               :img_url => params[:img_url],
               :clothing_type => params[:clothing_type],
               :cats => params[:cats]
               }
  if "Yes, it is correct" == params["correct"] && !item_in_output?(item_hash)
    File.open(OUTPUT_FILE,"a") do |f|
      f << "#{item_hash[:description].strip}\n"
      f << "- #{item_hash[:clothing_type].strip}\n"
    end
  else
    if item_hash[:attempted_clothing_types]
      item_hash[:attempted_clothing_types] = item_hash[:attempted_clothing_types].split
    else
      item_hash[:attempted_clothing_types] ||= []
    end
    item_hash[:attempted_clothing_types] << item_hash[:clothing_type]

    possible_clothing_types = CLOTHING_TYPES.select{|x,y| !item_hash[:attempted_clothing_types].include?(y[:bm].to_s)}
    
    if possible_clothing_types.empty?
      # reset attempted types
      item_hash[:attempted_clothing_types] = []
    end
    new_attempt = possible_clothing_types[rand(possible_clothing_types.size)]

    item_hash[:clothing_type] = new_attempt.last[:bm].to_s
    
    data << item_hash
  end

  show_question(data)
end

def item_in_output?(item)
  "0" != `grep "#{calc_full_desc(item)}" #{OUTPUT_FILE} | wc -l`.chomp.strip
end

def calc_full_desc(item_hash)
  (item_hash[:description]+" "+item_hash[:cats]).gsub("'","\'").strip
end

def show_question(data)
  begin
    item = data.pop(true)
    
    while item_in_output?(item)
      item = data.pop(true)
    end

    html = "<div style='float:right'>Items left to categorize: #{data.size}</div>"


    html += "<form method='post' action='save_item'>"
    html += "<input type='hidden' name='description' value=\"#{item[:description]}\" />"
    html += "<input type='hidden' name='product_url' value='#{item[:product_url]}' />"
    html += "<input type='hidden' name='img_url' value='#{item[:img_url]}' />"
    html += "<input type='hidden' name='clothing_type' value='#{item[:clothing_type]}' />"
    html += "<input type='hidden' name='cats' value='#{item[:cats]}' />"
    html += "<input type='hidden' name='attempted_clothing_types' value='#{item[:attempted_clothing_types].join(" ")}' />"
    html += "<input type='submit' value='Yes, it is correct' name='correct' /> <input type='submit' value='Wrong, ignore and move on' name='correct' /></form><br /><br />"

    html += "<h2>#{item[:description]}</h2><a href='#{item[:product_url]}' target='_blank'><img src='#{item[:img_url]}' />"
    html += "<br /><br />#{item[:product_url]}</a><br /><br />"

    clothing_type = CLOTHING_TYPES.select{|x,y| y[:bm].to_s == item[:clothing_type]}
    html += "Suspected clothing type: <b>#{clothing_type.first.first}</b><br /><br />"
    
    html += "Additional data pertaining to this item: <br /><br />"
    html += item[:cats] + "<br /><br />"

    html
  rescue => e
    "Congrats, no more items to categorize! <a href='/'>Please check back later for more items.</a>"
  end
end

reload(data)
