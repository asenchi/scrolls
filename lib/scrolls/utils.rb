require 'rainbow'

module Scrolls
  module Utils
    def hashify(d)
      last = d.pop
      return {} unless last
      return hashified_list(d).merge(last) if last.is_a?(Hash)
      d.push(last)
      hashified_list(d)
    end

    def hashified_list(l)
      return {} if l.empty?
      l.inject({}) do |h, i|
        h[i.to_sym] = true
        h
      end
    end

    def colorize_output(logdata)
      return logdata if logdata.empty?

      colorized_hash = {}
      setup_colors

      logdata.each_pair do |k, v| 
        k, v = colorize(k, v)
        colorized_hash[k] = v 
      end
      logdata.clear.update(colorized_hash)  
    end
    
    def setup_colors
      @standard_key_color ||= colors.fetch(:default_key, :red)
      @standard_value_color ||= colors.fetch(:default_value, :blue)
      @custom_key_color ||= colors.fetch(:custom_key, :red)
      @custom_value_color ||= colors.fetch(:custom_value, :blue)
    end

    def colorize(k, v)
      if scrolls_key?(k) || colors.empty?
        default_colorize(k, v)
      else
        custom_colorize(k, v)
      end
    end

    def scrolls_key?(k)
      [:now, :at, :reraise, :class, :message, :exception_id, :elapsed, "log_message", :site, :level].include?(k)
    end

    def default_colorize(key, value)
      return Rainbow(key).send(:color, @standard_key_color), Rainbow(value).send(:color, @standard_value_color)
    end
    
    def custom_colorize(key, value)
      return Rainbow(key).send(:color, @custom_key_color), Rainbow(value).send(:color, @custom_value_color)
    end

  end
end
