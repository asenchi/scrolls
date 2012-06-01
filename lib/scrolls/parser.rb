module Scrolls
  module Parser
    extend self

    def unparse(data)
      data.map do |(k,v)|
        if (v == true)
          "#{k}=true"
        elsif (v == false)
          "#{k}=false"
        elsif v.is_a?(Float)
          "#{k}=#{format("%.3f", v)}"
        elsif v.nil?
          "#{k}=nil"
        elsif v.is_a?(Time)
          "#{k}=#{Time.at(v).strftime("%FT%H:%M:%S%z")}"
        elsif v.is_a?(String) && v =~ /\\|\"| /
          v = v.gsub(/\\|"/) { |c| "\\#{c}" }
          "#{k}=\"#{v}\""
        else
          "#{k}=#{v}"
        end
      end.compact.join(" ")
    end

    def parse(data)
      vals = {}
      str = data.dup if data.is_a?(String)

      patterns = [
        /([^= ]+)="([^"\\]*(\\.[^"\\]*)*)"/, # key="\"literal\" escaped val"
        /([^= ]+)=([^ =]+)/                  # key=value
      ]

      patterns.each do |pattern|
        str.scan(pattern) do |match|
          v = match[1]
          v.gsub!(/\\"/, '"')                # unescape \"
          v.gsub!(/\\\\/, "\\")              # unescape \\

          if v.to_i.to_s == v                # cast value to int or float
            v = v.to_i
          elsif format("%.3f", v.to_f) == v
            v = v.to_f
          elsif v == "false"
            v = false
          elsif v == "true"
            v = true
          end

          vals[match[0]] = v
        end
        # sub value, leaving keys in order
        str.gsub!(pattern, "\\1")
      end

      # rebuild in-order key: value hash
      str.split.inject({}) do |h,k|
        h[k.to_sym] = vals[k]
        h
      end
    end
  end
end
