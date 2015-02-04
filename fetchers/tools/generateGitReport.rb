#git show 7209a678c944b8:config/launcher.us.yml


require 'rubygems'
require 'ruby-debug'
require 'yaml'
require 'time'
require 'erb'

##Usage:
#
# ruby tools\generateGitReport.rb <sha hash> <options>
# -n : Hide details about the fetcher updates
#

def staging?
  false
end

def production?
  true
end

class NoUsLauncherFile < StandardError; end;
class NoUkLauncherFile < StandardError; end;

def get_commit_log(skip)
  commit_date = ''
  data = `git log -1 --skip=#{skip}`
  this_sha = data.match(%r#commit (\w+)#i)[1] rescue nil
  commit_log = ''
  skip_lines = 0
  data.each{|line|
    date = line.match(%r#Date:\s(.*)#) rescue nil
    if !date.nil?
      commit_date = date[1].strip
    end
    unless skip_lines.eql?(4)
      skip_lines += 1
      next
    end
    commit_log += line
  }
  commit_log = commit_log.strip
  commit_log = commit_log.gsub(/\n/,' ')
  [commit_log,this_sha,commit_date]
end

def get_launcher_status(sha)
  launcher_us = `git show #{sha}:config/launcher.us.yml`
  us_yaml = YAML.load(ERB.new(launcher_us).result)[:fetchers] rescue nil
  raise NoUsLauncherFile if us_yaml.nil?
  launcher_uk = `git show #{sha}:config/launcher.uk.yml`
  uk_yaml = YAML.load(ERB.new(launcher_uk).result)[:fetchers] rescue nil
  raise NoUkLauncherFile if uk_yaml.nil?
  us = {}
  uk = {}
  us_yaml.each{|f|
    us[f[:name]] = f[:lang] || 'ruby'
  }
  uk_yaml.each{|f|
    uk[f[:name]] = f[:lang] || 'ruby'
  }
  [us,uk]
end

def get_modified_fetcher_info(line,this_sha,commit_log,commit_date, modified_fetchers)
  fetcher = line.match(%r#\+\+\+ b/fetchers/(\w+)/#)[1] rescue nil
  if !fetcher.nil?
    if modified_fetchers[fetcher].nil?
      modified_fetchers[fetcher] = {}
    end
    date_key = Time.parse(commit_date).to_s
    if modified_fetchers[fetcher][date_key].nil?
      modified_fetchers[fetcher][date_key] = [commit_log,this_sha]
    end
    [true,modified_fetchers]
  else
    [false,modified_fetchers]
  end
end

def get_framework_changes(line,this_sha,commit_log,commit_date,modified_framework)
  framework = line.match(%r#\+\+\+ b/lib/(.+)#)[1] rescue nil
  framework_2 = line.match(%r#\+\+\+ b/config/(.+)#)[1] rescue nil
  if !framework.nil? || !framework_2.nil?
    if modified_framework[this_sha].nil?
      modified_framework[this_sha] = [commit_log,commit_date,[]]
    end
    if !framework.nil?
      modified_framework[this_sha][2].push "/lib/#{framework}"
    elsif !framework_2.nil?
      modified_framework[this_sha][2].push "/config/#{framework_2}"
    end
  end
  modified_framework
end

def print_report_header(file_handle,git_sha,commit_date,num_commits,date)
  file_handle.write "Running Git report: #{date.year}/#{date.month}/#{date.day}\n\n"
  file_handle.write "Starting from SHA1 hash: #{git_sha}\n\t#{commit_date}\n\n"
  file_handle.write "Number of commits: #{num_commits}\n\n"
end

def print_framework_updates(file_handle,modified_framework)
  file_handle.write "Framework Updates:\n"
  if modified_framework.size.eql?(0)
    file_handle.write "\n\tNone"
  else
    modified_framework.each{|k,v|
      file_handle.write "\n\t#{k} : #{v[1]}\n\n"
      file_handle.write "\t\t#{v[0]}\n"
      v[2].each{|file|
        file_handle.write "\t\t\t#{file}\n"
      }
    }
  end
end

def print_fetcher_updates(file_handle,modified_fetchers,hide_details)
  file_handle.write "\n\nFetcher Updates:\n"
  if modified_fetchers.size.eql?(0)
    file_handle.write "\n\tNone"
  else
    modified_fetchers.keys.sort.each{|k|
      v = modified_fetchers[k]
      file_handle.write "\n\t#{k}\n"
      unless hide_details
        keys = modified_fetchers[k].keys.map{|x| Time.parse(x)}.sort
        keys.each{|key_time|
          file_handle.write "\n\t\t#{key_time} : #{modified_fetchers[k][key_time.to_s][1]}\n"
          #file_handle.write "\n\t\t#{modified_fetchers[k][key][1]}\n"
          file_handle.write "\t\t\t#{modified_fetchers[k][key_time.to_s][0]}\n"
        }
      end
    }
  end
end

def print_added_launchers(file_handle,prev_launcher_list,new_launcher_list)
  added_f = new_launcher_list.keys.reject{|k| prev_launcher_list.keys.include?(k)}
  if added_f.empty?
    file_handle.write "\t\t\tNone\n"
  else
    added_f.each{|fetcher|
      file_handle.write "\t\t\t#{fetcher} : #{new_launcher_list[fetcher]}\n"
    }
  end
end

def print_removed_launchers(file_handle,prev_launcher_list,new_launcher_list)
  removed_f = prev_launcher_list.keys.reject{|k| new_launcher_list.keys.include?(k)}
  if removed_f.empty?
    file_handle.write "\t\t\tNone\n"
  else
    removed_f.each{|fetcher|
      file_handle.write "\t\t\t#{fetcher} : #{prev_launcher_list[fetcher]}\n"
    }
  end
end

def print_changed_launchers(file_handle,prev_launcher_list,new_launcher_list)
  changed = new_launcher_list.select{|k,v| !v.eql?(prev_launcher_list[k]) && !prev_launcher_list[k].nil? }
  if changed.empty?
    file_handle.write "\t\t\tNone\n"
  else
    changed.each{|launcher,lang|
      file_handle.write "\t\t\t#{launcher} : #{prev_launcher_list[launcher]} -> #{new_launcher_list[launcher]}\n"
    }
  end
end

def print_launcher_info(file_handle,country,prev_launcher_list,new_launcher_list)
  file_handle.write "\n\t#{country}\n\n"
  file_handle.write "\t\tAdded:\n\n"
  print_added_launchers(file_handle,prev_launcher_list,new_launcher_list)
  file_handle.write "\n\t\tRemoved:\n\n"
  print_removed_launchers(file_handle,prev_launcher_list,new_launcher_list)
  file_handle.write "\n\t\tChanged:\n\n"
  print_changed_launchers(file_handle,prev_launcher_list,new_launcher_list)
end

def print_launcher_updates(file_handle,old_launchers,current_launchers)
  file_handle.write "\n\nLauncher Updates:\n"
  print_launcher_info(file_handle,'US:',old_launchers[0],current_launchers[0])
  print_launcher_info(file_handle,'UK:',old_launchers[1],current_launchers[1])
end

def get_spotcheck_data(line,should_test,should_spot_check)
  return if line.match(/^\+/)
  
  if line =~ /spot.?check/i
    should_spot_check << line.strip
  end
  
  if line =~ /test/i
    should_test << line.strip
  end
  
end

def print_section(file_handle,to_print,title)
  file_handle.write "\n\n#{title}\n"
  to_print.each do |log_entry|
    file_handle.write "\n\t#{log_entry}\n"
  end
end



### Begin program code
git_sha = ARGV[0]
hide_details = false
if ARGV.size > 1 && ARGV[1].eql?('-n')
  hide_details = true
end

this_sha = ''
num_commits = 0

modified_fetchers = {}
modified_framework = {}
old_launchers = []
current_launchers = []
should_spot_check = []
should_test = []

commit_date = ''
while true
  commit_log,this_sha,commit_date = get_commit_log(num_commits)

  ### GET LAUNCHER.*.YML NET CHANGES
  if current_launchers.empty?
    #most recent, starting commit
    current_launchers = get_launcher_status(this_sha)
  elsif git_sha.eql?(this_sha)
    #commit to check, least recent
    old_launchers = get_launcher_status(this_sha)
  end
  log_data = `git show #{this_sha}`
  log_data.each{|line|
    get_spotcheck_data(line,should_test,should_spot_check)
    should_next,modified_fetchers = get_modified_fetcher_info(line,this_sha,commit_log,commit_date,modified_fetchers)
    next if should_next
    modified_framework = get_framework_changes(line,this_sha,commit_log,commit_date,modified_framework)
  }
  num_commits += 1
  #puts this_sha
  if git_sha.eql?(this_sha)
    break
  end
end


date = Time.new
file_location = "git_report_#{date.year}_#{date.month}_#{(date.day.to_s.size == 1 ? "0":"")}#{date.day}.txt"
file_handle = File.open(file_location,'w')
print_report_header(file_handle,git_sha,commit_date,num_commits,date)
print_framework_updates(file_handle,modified_framework)
print_fetcher_updates(file_handle,modified_fetchers,hide_details)
print_launcher_updates(file_handle,old_launchers,current_launchers)
print_section(file_handle,should_spot_check.sort,"To Spotcheck:")
print_section(file_handle,should_test.sort, "Tests:")
file_handle.close

puts "Report written out to #{file_location}"
