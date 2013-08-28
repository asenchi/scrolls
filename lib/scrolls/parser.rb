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
          "#{k}=#{v.strftime("%FT%H:%M:%S%z")}"
        elsif v.is_a?(Hash)
          v.map { |(nk,nv)| "#{k}.#{nk.to_s}=#{handle_quotes(nv)}" }
        else
          v = handle_quotes(v)
          "#{k}=#{v}"
        end
      end.compact.join(" ")
    end

    def parse(data)
      vals = {}
      nvals = {}
      str = data.dup if data.is_a?(String)

      patterns = [
        /([^= ]+)="((?:\\.|[^"\\])*)"/, # key="\"literal\" escaped val"
        /([^= ]+)='((?:\\.|[^'\\])*)'/, # key='\'literal\' escaped val'
        /([^= ]+)\.([^= ]+)=([^ =]+)/,  # key.group=value
        /([^= ]+)=([^ =]+)/             # key=value
      ]

      patterns.each do |pattern|
        str.scan(pattern) do |match|
          k = match[0]         # Our key will always be our first match
          if match.length == 3 # If we are parsing a nested value (ie: k.n=v)
            n = match[1]       # Then our nested key will be our second match
            v = match[2]       # And our nested value will be our third match
          else
            v = match[1]       # Default
          end

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

          if n
            nvals[n.to_sym] = v
            vals[k] = nvals
          else
            vals[k] = v
          end
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

    private

    def handle_quotes(v)
      v = v.to_s
      has_single_quote = v.index("'")
      has_double_quote = v.index('"')
      if v =~ / /
        if has_single_quote && has_double_quote
          v = '"' + v.gsub(/\\|"/) { |c| "\\#{c}" } + '"'
        elsif has_double_quote
          v = "'" + v.gsub('\\', '\\\\\\') + "'"
        else
          v = '"' + v.gsub('\\', '\\\\\\') + '"'
        end
      elsif v =~ /=/
        v = '"' + v + '"'
      end
      v
    end
  end
end
