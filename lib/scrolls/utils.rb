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

  end
end
