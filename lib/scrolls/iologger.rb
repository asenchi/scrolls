module Scrolls
  class IOLogger
    def initialize(stream)
      if stream.respond_to?(:sync)
        stream.sync = true
      end
      @stream = stream
    end

    def log(data)
      @stream.write("#{data}\n")
    end
  end
end
