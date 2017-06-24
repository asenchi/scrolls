require "scrolls/parser"
require "scrolls/utils"
require "scrolls/syslog"

module Scrolls

  class TimeUnitError < RuntimeError; end

  module Log
    extend self

    extend Parser
    extend Utils

    LOG_LEVEL = (ENV['LOG_LEVEL'] || 6).to_i
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

    def add_global_context(new_data)
      default_global_context unless @global_context
      @global_context.update { |previous_data| previous_data.merge(new_data) }
    end

    def facility=(f)
      @facility = LOG_FACILITY_MAP[f] if f
      if Scrolls::SyslogLogger.opened?
        Scrolls::SyslogLogger.new(progname, facility)
      end
    end

    def facility
      @facility ||= default_log_facility
    end

    def stream=(out=nil)
      @defined = out.nil? ? false : true
      if out == 'syslog'
        @stream = Scrolls::SyslogLogger.new(progname, facility)
      else
        @stream = sync_stream(out)
      end
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

    def add_timestamp=(b)
      @add_timestamp = !!b
    end

    def add_timestamp
      @add_timestamp || false
    end

    def single_line_exceptions=(b)
      @single_line_exceptions = !!b
    end

    def single_line_exceptions?
      @single_line_exceptions || false
    end

    def log(data, &blk)
      # If we get a string lets bring it into our structure.
      if data.kind_of? String
        rawhash = { "log_message" => data }
      else
        rawhash = data
      end

      if gc = get_global_context
        ctx = gc.merge(context)
        logdata = ctx.merge(rawhash)
      end

      # By merging the logdata into the timestamp, rather than vice-versa, we
      # ensure that the timestamp comes first in the Hash, and is placed first
      # on the output, which helps with readability.
      logdata = { :now => Time.now.utc }.merge(logdata) if add_timestamp

      unless blk
        write(logdata)
      else
        start = Time.now
        res = nil
        log(logdata.merge(:at => "start"))
        begin
          res = yield
        rescue StandardError => e
          log(logdata.merge(
            :at           => "exception",
            :reraise      => true,
            :class        => e.class,
            :message      => e.message,
            :exception_id => e.object_id.abs,
            :elapsed      => calc_time(start, Time.now)
          ))
          raise e
        end
        log(logdata.merge(:at => "finish", :elapsed => calc_time(start, Time.now)))
        res
      end
    end

    def log_exception(data, e)
      sync_stream(STDERR) unless @defined

      # If we get a string lets bring it into our structure.
      if data.kind_of? String
        rawhash = { "log_message" => data }
      else
        rawhash = data
      end

      if gc = get_global_context
        logdata = gc.merge(rawhash)
      end

      excepdata = {
        :at           => "exception",
        :class        => e.class,
        :message      => e.message,
        :exception_id => e.object_id.abs
      }

      if e.backtrace
        if single_line_exceptions?
          btlines = []
          e.backtrace.each do |line|
            btlines << line.gsub(/[`'"]/, "")
          end

          if btlines.length > 0
            squish = { :site => btlines.join('\n') }
            log(logdata.merge(excepdata.merge(squish)))
          end
        else
          log(logdata.merge(excepdata))

          e.backtrace.each do |line|
            log(logdata.merge(excepdata).merge(
                :at           => "exception",
                :class        => e.class,
                :exception_id => e.object_id.abs,
                :site         => line.gsub(/[`'"]/, "")
            ))
          end
        end
      end
    end

    def with_context(prefix)
      return unless block_given?
      old = context
      self.context = old.merge(prefix)
      res = yield if block_given?
    ensure
      self.context = old
      res
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
      s
    end

    def write(data)
      if log_level_ok?(data[:level])
        msg = Oj.dump(parse(data))
        stream.print(msg + "\n")
      end
    end

    def log_level_ok?(level)
      if level
        LOG_LEVEL_MAP[level.to_s] <= LOG_LEVEL
      else
        true
      end
    end

    def progname
      File.basename($0)
    end

    def default_log_facility
      LOG_FACILITY
    end
  end
end
