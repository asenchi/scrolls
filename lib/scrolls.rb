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

  def context(data, &blk)
    Log.set_context(data, &blk)
  end

  module Log
    extend self

    LOG_LEVEL = (ENV["LOG_LEVEL"] || 3).to_i

    #http://tools.ietf.org/html/rfc5424#page-11
    LOG_LEVEL_MAP = {
      "emergency" => 0,
      "alert"     => 1,
      "critical"  => 2,
      "error"     => 3,
      "warning"   => 4,
      "notice"    => 5,
      "info"      => 6,
      "debug"     => 7
    }

    attr_accessor :stream, :context

    def start(out = nil)
      # This allows log_exceptions below to pick up the defined output,
      # otherwise stream out to STDERR
      @defined = out.nil? ? false : true

      sync_stream(out)
    end

    def sync_stream(out = nil)
      out = STDOUT if out.nil?
      @stream = out
      @stream.sync = true
    end

    def mtx
      @mtx ||= Mutex.new
    end

    def write(data)
      if log_level_ok?(data[:level])
        msg = unparse(data)
        mtx.synchronize do
          begin
            @stream.puts(msg)
          rescue NoMethodError => e
            puts "You need to start your logger, `Scrolls::Log.start`"
          end
        end
      end
    end

    def unparse(data)
      data.map do |(k, v)|
        if (v == true)
          k.to_s
        elsif v.is_a?(Float)
          "#{k}=#{format("%.3f", v)}"
        elsif v.nil?
          nil
        else
          v_str = v.to_s
          if (v_str =~ /^[a-zA-z0-9\-\_\.]+$/)
            "#{k}=#{v_str}"
          else
            "#{k}=\"#{v_str.sub(/".*/, "...")}\""
          end
        end
      end.compact.join(" ")
    end

    def log(data, &blk)
      if @context
        logdata = @context.merge(data)
      else
        logdata = data
      end

      unless blk
        write(logdata)
      else
        start = Time.now
        res = nil
        log(logdata.merge(:at => :start))
        begin
          res = yield
        rescue StandardError, Timeout::Error => e
          log(logdata.merge(
            :at           => :exception,
            :reraise      => true,
            :class        => e.class,
            :message      => e.message,
            :exception_id => e.object_id.abs,
            :elapsed      => Time.now - start
          ))
          raise(e)
        end
        log(logdata.merge(:at => :finish, :elapsed => Time.now - start))
        res
      end
    end

    def log_exception(data, e)
      sync_stream(STDERR) unless @defined
      log(data.merge(
        :exception    => true,
        :class        => e.class,
        :message      => e.message,
        :exception_id => e.object_id.abs
      ))
      if e.backtrace
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

    def log_level_ok?(level)
      if level
        LOG_LEVEL_MAP[level.to_s] <= LOG_LEVEL
      else
        true
      end
    end

    def set_context(prefix, &blk)
      # Initialize an empty context if the variable doesn't exist
      @context = {} unless @context
      @stash = [] unless @stash
      @stash << @context
      # Why isn't this merging
      @context = @context.merge(prefix)

      if blk
        yield
        @context = @stash.pop
      end
    end

    def clear_context
      @stash = []
      @context = {}
    end

  end
end
