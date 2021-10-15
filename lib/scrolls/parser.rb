require 'time'

module Scrolls
  module Parser
    extend self

    def unparse(data, escape_keys=false, strict_logfmt=false)
      data.map do |(k,v)|
        k = Scrolls::Utils.escape_chars(k) if escape_keys

        if (v == true)
          "#{k}=true"
        elsif (v == false)
          "#{k}=false"
        elsif v.is_a?(Float)
          "#{k}=#{format("%.3f", v)}"
        elsif v.nil?
          "#{k}=nil"
        elsif v.is_a?(Time)
          "#{k}=\"#{v.iso8601}\""
        else
          v = v.to_s
          has_single_quote = v.index("'")
          has_double_quote = v.index('"')
          if v =~ /[ =:,]/
            if (has_single_quote || strict_logfmt) && has_double_quote
              v = '"' + v.gsub(/\\|"/) { |c| "\\#{c}" } + '"'
            elsif has_double_quote
              v = "'" + v.gsub('\\', '\\\\\\') + "'"
            else
              v = '"' + v.gsub('\\', '\\\\\\') + '"'
            end
          end
          "#{k}=#{v}"
        end
      end.compact.join(" ")
    end

    def parse(data)
      vals = {}
      str = data.dup if data.is_a?(String)

      patterns = [
        /([^= ]+)="((?:\\.|[^"\\])*)"/, # key="\"literal\" escaped val"
        /([^= ]+)='((?:\\.|[^'\\])*)'/, # key='\'literal\' escaped val'
        /([^= ]+)=([^ =]+)/             # key=value
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
          else
            begin
              v = Time.iso8601(v)
            rescue ArgumentError
            end
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
