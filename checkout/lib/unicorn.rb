working_directory File.expand_path(File.join(File.dirname(__FILE__), '..'))
worker_processes 8
listen "/tmp/checkout.sock", :backlog => 5
listen 4567, :backlog=>0, :tcp_nopush => true
timeout 120
pid '/opt/checkout/shared/pids/unicorn.pid'

# combine REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

before_fork do |server, worker|

  # The last worker spawned
  # will then kill off the old master process with a SIGQUIT.
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      if (worker.nr + 1) >= server.worker_processes
        Process.kill(:QUIT, File.read(old_pid).to_i)
      end
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end

  # optionally throttle the master from forking too quickly by sleeping
  sleep 1
end
