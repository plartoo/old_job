
class HtmlLogger

  def initialize(file_stream)
    @stream = file_stream
  end

  def <<(string)
    @stream << string
  end

end
