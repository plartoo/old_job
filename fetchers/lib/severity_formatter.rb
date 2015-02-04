class SeverityFormatter < Logger::Formatter # :nodoc:
  def call(severity, timestamp, progname, msg)
    "#{severity}:  #{msg}\n"
  end
end