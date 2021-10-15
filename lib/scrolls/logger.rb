require "syslog"

require "scrolls/parser"
require "scrolls/iologger"
require "scrolls/sysloglogger"
require "scrolls/utils"

module Scrolls
  # Default log facility
  LOG_FACILITY = ENV['LOG_FACILITY'] || Syslog::LOG_USER

  # Default log level
  LOG_LEVEL = (ENV['LOG_LEVEL'] || 6).to_i

  # Default syslog options
  SYSLOG_OPTIONS = Syslog::LOG_PID|Syslog::LOG_CONS

  class TimeUnitError < RuntimeError; end
  class LogLevelError < StandardError; end

  # Top level class to hold our global context
  #
  # Global context is defined using Scrolls#init
  class GlobalContext
    def initialize(ctx)
      @ctx = ctx || {}
    end

    def to_h
      @ctx
    end
  end

  class Logger

    attr_reader :logger
    attr_accessor :exceptions, :timestamp

    def initialize(options={})
      @stream        = options.fetch(:stream, STDOUT)
      @log_facility  = options.fetch(:facility, LOG_FACILITY)
      @time_unit     = options.fetch(:time_unit, "seconds")
      @timestamp     = options.fetch(:timestamp, false)
      @exceptions    = options.fetch(:exceptions, "single")
      @global_ctx    = options.fetch(:global_context, {})
      @syslog_opts   = options.fetch(:syslog_options, SYSLOG_OPTIONS)
      @escape_keys   = options.fetch(:escape_keys, false)
      @strict_logfmt = options.fetch(:strict_logfmt, false)

      # Our main entry point to ensure our options are setup properly
      setup!
    end

    def context
      if Thread.current.thread_variables.include?(:scrolls_context)
        Thread.current.thread_variable_get(:scrolls_context)
      else
        Thread.current.thread_variable_set(:scrolls_context, {})
      end
    end

    def context=(h)
      Thread.current.thread_variable_set(:scrolls_context, h || {})
    end

    def stream
      @stream
    end

    def stream=(s)
      # Return early to avoid setup
      return if s == @stream

      @stream = s
      setup_stream
    end

    def escape_keys?
      @escape_keys
    end

    def strict_logfmt?
      @strict_logfmt
    end

    def syslog_options
      @syslog_opts
    end

    def facility
      @facility
    end

    def facility=(f)
      if f
        setup_facility(f)
        # If we are using syslog, we need to setup our connection again
        if stream == "syslog"
          @logger = Scrolls::SyslogLogger.new(
                      progname,
                      syslog_options,
                      facility
                    )
        end
      end
    end

    def time_unit
      @time_unit
    end

    def time_unit=(u)
      @time_unit = u
      setup_time_unit
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
      logdata = { :now => Time.now.utc }.merge(logdata) if prepend_timestamp?

      unless blk
        write(logdata)
      else
        start = Time.now
        res = nil
        log(logdata.merge(:at => "start"))
        begin
          res = yield
        rescue StandardError => e
          logdata.merge!({
            at:           "exception",
            reraise:      true,
            class:        e.class,
            message:      e.message,
            exception_id: e.object_id.abs,
            elapsed:      calculate_time(start, Time.now)
          })
          logdata.delete_if { |k,v| k if v == "" }
          log(logdata)
          raise e
        end
        log(logdata.merge(:at => "finish", :elapsed => calculate_time(start, Time.now)))
        res
      end
    end

    def log_exception(e, data=nil)
      unless @defined
        @stream = STDERR
        setup_stream
      end

      # We check our arguments for type
      case data
      when String
        rawhash = { "log_message" => data }
      when Hash
        rawhash = data
      else
        rawhash = {}
      end

      if gc = @global_context.to_h
        logdata = gc.merge(rawhash)
      end

      excepdata = {
        at:           "exception",
        class:        e.class,
        message:      e.message,
        exception_id: e.object_id.abs
      }

      excepdata.delete_if { |k,v| k if v == "" }

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
      setup_global_context
      prepend_timestamp?
      setup_facility
      setup_stream
      single_line_exceptions?
      setup_time_unit
    end

    def setup_global_context
      # Builds up an immutable object for our global_context
      # This is not backwards compatiable and was introduced after 0.3.7.
      # Removes ability to add to global context once we initialize our
      # logging object. This also deprecates #add_global_context.
      @global_context = GlobalContext.new(@global_ctx)
      @global_context.freeze
    end

    def prepend_timestamp?
      @timestamp
    end

    def setup_facility(f=nil)
      if f
        @facility = LOG_FACILITY_MAP.fetch(f, LOG_FACILITY)
      else
        @facility = LOG_FACILITY_MAP.fetch(@log_facility, LOG_FACILITY)
      end
    end

    def setup_stream
      unless @stream == STDOUT
        # Set this so we know we aren't using our default stream
        @defined = true
      end

      if @stream == "syslog"
        @logger = Scrolls::SyslogLogger.new(
                    progname,
                    syslog_options,
                    facility
                  )
      else
        @logger = IOLogger.new(@stream)
      end
    end

    def single_line_exceptions?
      return false if @exceptions == "multi"
      true
    end

    def setup_time_unit
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

    # We need this for our syslog setup
    def progname
      File.basename($0)
    end

    def calculate_time(start, finish)
      translate_time_unit unless @t
      ((finish - start).to_f * @t)
    end

    def log_level_ok?(level)
      if level
        raise LogLevelError, "Log level unknown" unless LOG_LEVEL_MAP.key?(level)
        LOG_LEVEL_MAP[level.to_s] <= LOG_LEVEL
      else
        true
      end
    end

    def write(data)
      if log_level_ok?(data[:level])
        msg = Scrolls::Parser.unparse(data, escape_keys=escape_keys?, strict_logfmt=strict_logfmt?)
        @logger.log(msg)
      end
    end

  end
end
