require "scrolls/logger"
require "scrolls/version"

module Scrolls
  extend self

  # Public: Initialize a Scrolls logger
  #
  # options - A hash of key/values for configuring Scrolls
  #   stream         - Stream to output data (default: STDOUT)
  #   log_facility   - Syslog facility (default: Syslog::LOG_USER)
  #   time_unit      - Unit of time (default: seconds)
  #   timestamp      - Prepend logs with a timestamp (default: false)
  #   exceptions     - Method for outputting exceptions (default: single line)
  #   global_context - Immutable context to prepend all messages with
  #   syslog_options - Syslog options (default: Syslog::LOG_PID|Syslog::LOG_CONS)
  #   escape_keys    - Escape chars in keys
  #   strict_logfmt  - Always use double quotes to quote values
  #
  def init(options={})
    # Set a hint whether #init was called.
    @initialized = true
    @log = Logger.new(options)
  end

  # Public: Get the primary logger
  #
  def logger
    @log.logger
  end

  # Public: Set a context in a block for logs
  #
  # data - A hash of key/values to prepend to each log in a block
  # blk  - The block that our context wraps
  #
  # Examples:
  #
  def context(data, &blk)
    @log.with_context(data, &blk)
  end

  # Public: Get the global context that prefixs all logs
  #
  def global_context
    @log.global_context
  end

  # Public: Log data and/or wrap a block with start/finish
  #
  # data - A hash of key/values to log
  # blk  - A block to be wrapped by log lines
  #
  # Examples:
  #
  #   Scrolls.log(test: "test")
  #   test=test
  #   => nil
  #
  #   Scrolls.log(test: "test") { puts "inner block" }
  #   test=test at=start
  #   inner block
  #   test=test at=finish elapsed=0.000
  #   => nil
  #
  def log(data, &blk)
    # Allows us to call #log directly and initialize defaults
    @log = Logger.new({}) unless @initialized

    @log.log(data, &blk)
  end

  # Public: Log an exception
  #
  # e    - An exception to pass to the logger
  # data - A hash of key/values to log
  #
  # Examples:
  #
  #   begin
  #     raise Exception
  #   rescue Exception => e
  #     Scrolls.log_exception(e, {test: "test"})
  #   end
  #   test=test at=exception class=Exception message=Exception exception_id=70321999017240
  #   ...
  #
  def log_exception(e, data)
    # Allows us to call #log directly and initialize defaults
    @log = Logger.new({}) unless @initialized

    @log.log_exception(e, data)
  end

  # Public: Setup a logging facility (default: Syslog::LOG_USER)
  #
  # facility - Syslog facility
  #
  # Examples
  #
  #   Scrolls.facility = Syslog::LOG_LOCAL7
  #
  def facility=(f)
    @log.facility=(f)
  end

  # Public: Return the Syslog facility
  #
  # Examples
  #
  #   Scrolls.facility
  #   => 8
  #
  def facility
    @log.facility
  end

  # Public: Setup a new output (default: STDOUT)
  #
  # out - New output
  #
  # Options
  #
  #   syslog - Load 'Scrolls::SyslogLogger'
  #
  # Examples
  #
  #   Scrolls.stream = StringIO.new
  #
  def stream=(out)
    @log.stream=(out)
  end

  # Public: Return the stream
  #
  # Examples
  #
  #   Scrolls.stream
  #   => #<IO:<STDOUT>>
  #
  def stream
    @log.stream
  end

  # Public: Set the time unit we use for 'elapsed' (default: "seconds")
  #
  # unit - The time unit ("milliseconds" currently supported)
  #
  # Examples
  #
  #   Scrolls.time_unit = "milliseconds"
  #
  def time_unit=(unit)
    @log.time_unit = unit
  end

  # Public: Return the time unit currently configured
  #
  # Examples
  #
  #   Scrolls.time_unit
  #   => "seconds"
  #
  def time_unit
    @log.time_unit
  end

  # Public: Set whether to include a timestamp (now=<ISO8601>) field in the log
  # output (default: false)
  #
  # Examples
  #
  #   Scrolls.add_timestamp = true
  #
  def add_timestamp=(boolean)
    @log.timestamp = boolean
  end

  # Public: Return whether the timestamp field will be included in the log
  # output.
  #
  # Examples
  #
  #   Scrolls.add_timestamp
  #   => true
  #
  def add_timestamp
    @log.timestamp
  end

  # Public: Set whether exceptions should generate a single log
  # message. (default: false)
  #
  # Examples
  #
  #   Scrolls.single_line_exceptions = true
  #
  def single_line_exceptions=(boolean)
    @log.exceptions = boolean
  end

  # Public: Return whether exceptions generate a single log message.
  #
  # Examples
  #
  #   Scrolls.single_line_exceptions
  #   => true
  #
  def single_line_exceptions?
    @log.single_line_exceptions?
  end

  # Public: Convience method for Logger replacement
  #
  # data - A hash of key/values to log
  # blk  - A block to be wrapped by log lines
  #
  # Examples:
  #
  #   Scrolls.debug(test: "test")
  #   test=test level=debug
  #   => nil
  #
  def debug(data, &blk)
    data = data.merge(:level => "debug") if data.is_a?(Hash)
    @log.log(data, &blk)
  end

  # Public: Convience method for Logger replacement
  #
  # Translates the `level` to Syslog equivalent
  #
  # data - A hash of key/values to log
  # blk  - A block to be wrapped by log lines
  #
  # Examples:
  #
  #   Scrolls.error(test: "test")
  #   test=test level=warning
  #   => nil
  #
  def error(data, &blk)
    data = data.merge(:level => "warning") if data.is_a?(Hash)
    @log.log(data, &blk)
  end

  # Public: Convience method for Logger replacement
  #
  # Translates the `level` to Syslog equivalent
  #
  # data - A hash of key/values to log
  # blk  - A block to be wrapped by log lines
  #
  # Examples:
  #
  #   Scrolls.fatal(test: "test")
  #   test=test level=error
  #   => nil
  #
  def fatal(data, &blk)
    data = data.merge(:level => "error") if data.is_a?(Hash)
    @log.log(data, &blk)
  end

  # Public: Convience method for Logger replacement
  #
  # Translates the `level` to Syslog equivalent
  #
  # data - A hash of key/values to log
  # blk  - A block to be wrapped by log lines
  #
  # Examples:
  #
  #   Scrolls.info(test: "test")
  #   test=test level=info
  #   => nil
  #
  def info(data, &blk)
    data = data.merge(:level => "info") if data.is_a?(Hash)
    @log.log(data, &blk)
  end

  # Public: Convience method for Logger replacement
  #
  # Translates the `level` to Syslog equivalent
  #
  # data - A hash of key/values to log
  # blk  - A block to be wrapped by log lines
  #
  # Examples:
  #
  #   Scrolls.warn(test: "test")
  #   test=test level=notice
  #   => nil
  #
  def warn(data, &blk)
    data = data.merge(:level => "notice") if data.is_a?(Hash)
    @log.log(data, &blk)
  end

  # Public: Convience method for Logger replacement
  #
  # Translates the `level` to Syslog equivalent
  #
  # data - A hash of key/values to log
  # blk  - A block to be wrapped by log lines
  #
  # Examples:
  #
  #   Scrolls.unknown(test: "test")
  #   test=test level=alert
  #   => nil
  #
  def unknown(data, &blk)
    data = data.merge(:level => "alert") if data.is_a?(Hash)
    @log.log(data, &blk)
  end

  # Internal: The Logger initialized by #init
  #
  def internal
    @log
  end

end
