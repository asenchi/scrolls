module Scrolls
  class IOLog
    def initialize(stream)
      stream.sync = true
      @stream = stream
    end

    def log(data)
      @stream.write("#{data}\n")
    end
  end
end
