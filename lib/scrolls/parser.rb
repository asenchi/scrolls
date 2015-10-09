require 'time'

module Scrolls
  module Parser
    extend self

    def parse(data)
      result = {}

      data.map do |(k,v)|
        if v.is_a?(Float)
          result[k] = format("%.3f", v)
        elsif v.is_a?(Time)
          result[k] = v.iso8601
        elsif v.is_a?(String)
          result[k] = v.force_encoding('UTF-8')
        elsif v.is_a?(Hash)
          result[k] = parse(v)
        else
          result[k] = v
        end
      end

      result
    end
  end
end
