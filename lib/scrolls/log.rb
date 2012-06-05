require "scrolls/parser"
require "scrolls/utils"

module Scrolls
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
      unless blk
        write(data)
      else
        start = Time.now
        res = nil
        log(data.merge(at: "start"))
        begin
          res = yield
        rescue StandardError, Timeout::Error => e
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
        log(data.merge(at: "finish", elapsed: calc_time(start, Time.now)))
        res
      end
    end

    def log_exception(data, e)
      sync_stream(STDERR) unless @defined

      log(data.merge(
          :at => "exception",
          :class        => e.class,
          :message      => e.message,
          :exception_id => e.object_id.abs
      ))
      if e.backtrace
        bt = e.backtrace.reverse
        bt[0, bt.size-6].each do |line|
          log(data.merge(
              :at => "exception",
              :class => e.message,
              :exception_id => e.object_id.abs,
              :site => line.gsub(/[`'"]/, "")
          ))
        end
      end
    end

    private

    def set_time_unit(u=nil)
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
