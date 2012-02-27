require "thread"

require "scrolls/version"

module Scrolls
  extend self

  def log(data, &blk)
    Log.log(data, &blk)
  end

  def log_exception(data, e)
    Log.log_exception(data, e)
  end

  module Log
    extend self

    def start
      $stdout.sync = $stderr.sync = true
      log(:log => true, :start => true)
    end

    def mtx
      @mtx ||= Mutex.new
    end

    def write(data)
      msg = unparse(data)
      mtx.synchronize do
        $stdout.puts(msg)
      end
    end

    def unparse(data)
      data.map do |(k, v)|
        if (v == true)
          k.to_s
        elsif (v == false)
          "#{k}=false"
        elsif v.is_a?(String) # escape and quote v with ' or \ or multiple words
          v = v.gsub(/\\|'/) { |c| "\\#{c}" }
          "#{k}='#{v}'"
        elsif v.is_a?(Float)
          "#{k}=#{format("%.3f", v)}"
        else
          "#{k}=#{v}"
        end
      end.compact.join(" ")
    end

    def log(data, &blk)
      unless blk
        write(data)
      else
        start = Time.now
        res = nil
        log(data.merge(:at => :start))
        begin
          res = yield
        rescue StandardError, Timeout::Error => e
          log(data.merge(
            :at           => :exception,
            :reraise      => true,
            :class        => e.class,
            :message      => e.message,
            :exception_id => e.object_id.abs,
            :elapsed      => Time.now - start
          ))
          raise(e)
        end
        log(data.merge(:at => :finish, :elapsed => Time.now - start))
        res
      end
    end

    def log_exception(data, e)
      log(data.merge(
        :exception    => true,
        :class        => e.class,
        :message      => e.message,
        :exception_id => e.object_id.abs
      ))
      bt = e.backtrace.reverse
      bt[0, bt.size-6].each do |line|
        log(data.merge(
          :exception    => true,
          :exception_id => e.object_id.abs,
          :site         => line.gsub(/[`'"]/, "")
        ))
      end
    end
  end
end
