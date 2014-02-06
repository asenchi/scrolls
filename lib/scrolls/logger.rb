require "scrolls/parser"
require "scrolls/syslog"

module Scrolls
  class TimeUnitError < RuntimeError; end

  class GlobalContext
    attr_reader :context
    def initialize(context)
      @context = context || {}
    end

    def to_h
      @context
    end
  end

  class Log
    LOG_FACILITY = ENV['LOG_FACILITY'] || Syslog::LOG_USER
    LOG_FACILITY_MAP = {
      "auth"     => Syslog::LOG_AUTH,
      "authpriv" => Syslog::LOG_AUTHPRIV,
      "cron"     => Syslog::LOG_CRON,
      "daemon"   => Syslog::LOG_DAEMON,
      "ftp"      => Syslog::LOG_FTP,
      "kern"     => Syslog::LOG_KERN,
      "mail"     => Syslog::LOG_MAIL,
      "news"     => Syslog::LOG_NEWS,
      "syslog"   => Syslog::LOG_SYSLOG,
      "user"     => Syslog::LOG_USER,
      "uucp"     => Syslog::LOG_UUCP,
      "local0"   => Syslog::LOG_LOCAL0,
      "local1"   => Syslog::LOG_LOCAL1,
      "local2"   => Syslog::LOG_LOCAL2,
      "local3"   => Syslog::LOG_LOCAL3,
      "local4"   => Syslog::LOG_LOCAL4,
      "local5"   => Syslog::LOG_LOCAL5,
      "local6"   => Syslog::LOG_LOCAL6,
      "local7"   => Syslog::LOG_LOCAL7,
    }

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

    attr_reader :logger
    attr_accessor :exceptions, :timestamp

    def initialize(options={})
      @stream     = options.fetch(:stream, STDOUT)
      @facility   = options.fetch(:facility, LOG_FACILITY)
      @time_unit  = options.fetch(:time_unit, "seconds")
      @timestamp  = options.fetch(:timestamp, false)
      @exceptions = options.fetch(:exceptions, "single")
      @global_ctx = options.fetch(:global_context, {})

      setup!
    end

    def context
      Thread.current[:scrolls_context] ||= {}
    end

    def context=(h)
      Thread.current[:scrolls_context] = h
    end

    def stream
      @stream
    end

    def stream=(stream)
      # Return early to avoid setup
      return if stream == @stream
      
      @stream = stream
      setup_stream
    end

    def facility
      @facility ||= LOG_FACILITY
    end

    def facility=(f)
      if f
        @facility = LOG_FACILITY_MAP[f]
        # Assume we are using syslog and set it up again
        @logger = Scrolls::SyslogLogger.new(progname, facility)
      end
    end

    def time_unit
      @time_unit
    end

    def time_unit=(u)
      @time_unit = u
      translate_time_unit
    end

    def global_context
      @global_context.to_h
    end

    def log(data, &blk)
      # If we get a string lets bring it into our structure.
      if data.kind_of? String
        rawhash = { "log_message" => data }
      else
        rawhash = data
      end

      if gc = @global_context.to_h
        ctx = gc.merge(context)
        logdata = ctx.merge(rawhash)
      end

      # By merging the logdata into the timestamp, rather than vice-versa, we
      # ensure that the timestamp comes first in the Hash, and is placed first
      # on the output, which helps with readability.
      logdata = { :now => Time.now.utc }.merge(logdata) if append_timestamp?

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
            :elapsed      => calculate_time(start, Time.now)
          ))
          raise e
        end
        log(logdata.merge(:at => "finish", :elapsed => calculate_time(start, Time.now)))
        res
      end
    end

    def log_exception(data, e)
      unless @defined
        @stream = STDERR
        setup_stream
      end

      # If we get a string lets bring it into our structure.
      if data.kind_of? String
        rawhash = { "log_message" => data }
      else
        rawhash = data
      end

      if gc = @global_context.to_h
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
          lines = e.backtrace.map { |line| line.gsub(/[`'"]/, "") }

          if lines.length > 0
            excepdata[:site] = lines.join('\n')
            log(logdata.merge(excepdata))
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

    def setup!
      build_global_context
      append_timestamp?
      setup_stream
      single_line_exceptions?
      translate_time_unit
    end

    def build_global_context
      # Builds up an immutable object for our global_context
      # This is not backwards compatiable and was introduced after 0.3.7.
      # Removes ability to add to global context once we initialize our
      # logging object. This also deprecates #add_global_context.
      @global_context = GlobalContext.new(@global_ctx)
      @global_context.freeze
    end

    def append_timestamp?
      @timestamp
    end

    def setup_stream
      unless @stream == STDOUT
        @defined = true
      end

      if @stream == "syslog"
        @logger = Scrolls::SyslogLogger.new(progname, facility)
      else
        @logger = sync_stream(@stream)
      end
    end

    def single_line_exceptions?
      return false if @exceptions == "multi"
      true
    end

    def translate_time_unit
      unless %w{s ms seconds milliseconds}.include? @time_unit
        raise TimeUnitError, "Specify the following: s, ms, seconds, milliseconds"
      end

      case @time_unit
      when %w{s seconds}
        @t = 1.0
      when %w{ms milliseconds}
        @t = 1000.0
      else
        @t = 1.0
      end
    end
    
    def sync_stream(out)
      begin
        out.sync = true
      rescue NoMethodError
        # Trust that the object knows what it's doing
      end
      out
    end

    def progname
      File.basename($0)
    end

    def calculate_time(start, finish)
      translate_time_unit unless @t
      ((finish - start).to_f * @t)
    end

    def log_level_ok?(level)
      if level
        LOG_LEVEL_MAP[level.to_s] <= LOG_LEVEL
      else
        true
      end
    end

    def mtx
      @mtx ||= Mutex.new
    end

    def write(data)
      if log_level_ok?(data[:level])
        msg = Scrolls::Parser.unparse(data)
        mtx.synchronize do
          begin
            logger.puts(msg)
          rescue NoMethodError => e
            raise
          end
        end
      end
    end

  end
end
