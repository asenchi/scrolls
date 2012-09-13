require "scrolls/parser"
require "scrolls/utils"

module Scrolls

  class TimeUnitError < RuntimeError; end

  module Log
    extend self

    extend Parser
    extend Utils

    LOG_LEVEL = (ENV['LOG_LEVEL'] || 3).to_i
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

    def context
      Thread.current[:scrolls_context] ||= {}
    end

    def context=(h)
      Thread.current[:scrolls_context] = h
    end

    def global_context
      get_global_context
    end

    def global_context=(data)
      set_global_context(data)
    end

    def stream=(out=nil)
      @defined = out.nil? ? false : true

      @stream = sync_stream(out)
    end

    def stream
      @stream ||= sync_stream
    end

    def time_unit=(u)
      set_time_unit(u)
    end

    def time_unit
      @tunit ||= default_time_unit
    end

    def log(data, &blk)
      if gc = get_global_context
        ctx = gc.merge(context)
        logdata = ctx.merge(data)
      end

      unless blk
        write(logdata)
      else
        start = Time.now
        res = nil
        log(logdata.merge(:at => "start"))
        begin
          res = yield
        rescue StandardError => e
          log(
            :at           => "exception",
            :reraise      => true,
            :class        => e.class,
            :message      => e.message,
            :exception_id => e.object_id.abs,
            :elapsed      => calc_time(start, Time.now)
          )
          raise e
        end
        log(logdata.merge(:at => "finish", :elapsed => calc_time(start, Time.now)))
        res
      end
    end

    def log_exception(data, e)
      sync_stream(STDERR) unless @defined

      if gc = get_global_context
        logdata = gc.merge(data)
      end

      log(logdata.merge(
          :at => "exception",
          :class        => e.class,
          :message      => e.message,
          :exception_id => e.object_id.abs
      ))
      if e.backtrace
        bt = e.backtrace.reverse
        bt[0, bt.size-6].each do |line|
          log(logdata.merge(
              :at => "exception",
              :class => e.message,
              :exception_id => e.object_id.abs,
              :site => line.gsub(/[`'"]/, "")
          ))
        end
      end
    end

    def with_context(prefix)
      return unless block_given?
      old = context
      self.context = old.merge(prefix)
      yield if block_given?
      self.context = old
    end

    private

    def get_global_context
      default_global_context unless @global_context
      @global_context.value
    end

    def set_global_context(data=nil)
      default_global_context unless @global_context
      @global_context.update { |_| data }
    end

    def default_global_context
      @global_context = Atomic.new({})
    end

    def set_time_unit(u=nil)
      unless ["ms","milli","milliseconds","s","seconds"].include?(u)
        raise TimeUnitError, "Specify only 'seconds' or 'milliseconds'"
      end

      if ["ms", "milli", "milliseconds", 1000].include?(u)
        @tunit = "milliseconds"
        @t = 1000.0
      else
        default_time_unit
      end
    end

    def default_time_unit
      @t = 1.0
      @tunit = "seconds"
    end

    def calc_time(start, finish)
      default_time_unit unless @t
      ((finish - start).to_f * @t)
    end

    def mtx
      @mtx ||= Mutex.new
    end

    def sync_stream(out=nil)
      out = STDOUT if out.nil?
      s = out
      s.sync = true
      s
    end

    def write(data)
      if log_level_ok?(data[:level])
        msg = unparse(data)
        mtx.synchronize do
          begin
            stream.puts(msg)
          rescue NoMethodError => e
            raise
          end
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

  end
end
