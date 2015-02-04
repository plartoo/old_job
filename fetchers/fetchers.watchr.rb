# Run me with:
#
#   $ watchr fetcher.watchr.rb

# --------------------------------------------------
# Convenience Methods
# --------------------------------------------------
def all_test_files
  Dir['test/**/test_*.rb'] - ['test/test_helper.rb']
end

def run(cmd)
  puts(cmd)
  system(cmd)
end

def run_all_tests
  cmd = "ruby -rubygems -Ilib -e'%w( #{all_test_files.join(' ')} ).each {|file| require file }'"
  run(cmd)
end

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------
watch( 'launcher.rb') {|m| run("ruby -rubygems test/launcher_test.rb")}
watch( '^lib/(.*)\.rb'         )   { |m| run( "ruby -rubygems test/%s_test.rb" % m[1] ) }
watch( '^lib/data/(.*)\.rb'         )   { |m| run( "ruby -rubygems test/%s_test.rb" % m[1] ) }
watch( '^test/(.*)\.rb') {|m| run("ruby -rubygems test/%s.rb" % m[1] )}
watch( '^test/fixtures/size_mapping_regression\.db') {|m| run("ruby -rubygems test/size_test.rb" % m[1] )}

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
# Ctrl-\
#Signal.trap('QUIT') do
#  puts " --- Running all tests ---\n\n"
#  run_all_tests
#end

# Ctrl-C
Signal.trap('INT') { abort("\n") }