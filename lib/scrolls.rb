require "thread"
require "scrolls/atomic"
require "scrolls/log"
require "scrolls/version"

module Scrolls
  extend self

  # Public: Initialize a Scrolls logger
  #
  # Convienence method to prepare for future releases. Currently mimics
  # behavior found in other methods. This prepares the developer for a future
  # backward incompatible change, see:
  # https://github.com/asenchi/scrolls/pull/54
  #
  # options - A hash of key/values for configuring Scrolls
  #
  def init(options)
    stream     = options.fetch(:stream, STDOUT)
    facility   = options.fetch(:facility, Syslog::LOG_USER)
    time_unit  = options.fetch(:time_unit, "seconds")
    timestamp  = options.fetch(:timestamp, false)
    exceptions = options.fetch(:exceptions, "multi")
    global_ctx = options.fetch(:global_context, {})

    Log.stream    = stream
    Log.facility  = facility if facility
    Log.time_unit = time_unit unless time_unit == "seconds"
    Log.add_timestamp = timestamp unless timestamp == false

    if exceptions == "single"
      Log.single_line_exceptions = true
    end

    unless global_ctx == {}
      Log.global_context = global_ctx
    end
  end

  # Public: Set a context in a block for logs
  #
  # data - A hash of key/values to prepend to each log in a block
  # blk  - The block that our context wraps
  #
  # Examples:
  #
  def context(data, &blk)
    Log.with_context(data, &blk)
  end

  # Deprecated: Get or set a global context that prefixs all logs
  #
  # data - A hash of key/values to prepend to each log
  #
  # This method will be deprecated two releases after 0.3.8.
  # See https://github.com/asenchi/scrolls/releases/tag/v0.3.8
  # for more details.
  #
  def global_context(data=nil)
    $stderr.puts "global_context() will be deprecated after v0.3.8, please see https://github.com/asenchi/scrolls for more information."
    warn({:message => "global_context() will be deprecated after v0.3.8, please see https://github.com/asenchi/scrolls for more information."})
    if data
      Log.global_context = data
    else
      Log.global_context
    end
  end

  # Deprecated: Get or set a global context that prefixs all logs
  #
  # data - A hash of key/values to prepend to each log
  #
  # This method will be deprecated two releases after 0.3.8.
  # See https://github.com/asenchi/scrolls/releases/tag/v0.3.8
  # for more details.
  #
  def add_global_context(data)
    $stderr.puts "add_global_context will be deprecated after v0.3.8, please see https://github.com/asenchi/scrolls for more information."
    warn({:message => "add_global_context will be deprecated after v0.3.8, please see https://github.com/asenchi/scrolls for more information."})
    Log.add_global_context(data)
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
    Log.log(data, &blk)
  end

  # Public: Log an exception
  #
  # data - A hash of key/values to log
  # e    - An exception to pass to the logger
  #
  # Examples:
  #
  #   begin
  #     raise Exception
  #   rescue Exception => e
  #     Scrolls.log_exception({test: "test"}, e)
  #   end
  #   test=test at=exception class=Exception message=Exception exception_id=70321999017240
  #   ...
  #
  def log_exception(data, e)
    Log.log_exception(data, e)
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
    Log.facility=(f)
  end

  # Public: Return the Syslog facility
  #
  # Examples
  #
  #   Scrolls.facility
  #   => 8
  #
  def facility
    Log.facility
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
    Log.stream=(out)
  end

  # Public: Return the stream
  #
  # Examples
  #
  #   Scrolls.stream
  #   => #<IO:<STDOUT>>
  #
  def stream
    Log.stream
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
    Log.time_unit=(unit)
  end

  # Public: Return the time unit currently configured
  #
  # Examples
  #
  #   Scrolls.time_unit
  #   => "seconds"
  #
  def time_unit
    Log.time_unit
  end

  # Public: Set whether to include a timestamp (now=<ISO8601>) field in the log
  # output (default: false)
  #
  # Examples
  #
  #   Scrolls.add_timestamp = true
  #
  def add_timestamp=(boolean)
    Log.add_timestamp = boolean
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
    Log.add_timestamp
  end

  # Public: Set whether exceptions should generate a single log
  # message. (default: false)
  #
  # Examples
  #
  #   Scrolls.single_line_exceptions = true
  #
  def single_line_exceptions=(boolean)
    Log.single_line_exceptions = boolean
  end

  # Public: Return whether exceptions generate a single log message.
  #
  # Examples
  #
  #   Scrolls.single_line_exceptions
  #   => true
  #
  def single_line_exceptions?
    Log.single_line_exceptions
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
    data = data.merge(:level => "debug")
    Log.log(data, &blk)
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
    data = data.merge(:level => "warning")
    Log.log(data, &blk)
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
    data = data.merge(:level => "error")
    Log.log(data, &blk)
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
    data = data.merge(:level => "info")
    Log.log(data, &blk)
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
    data = data.merge(:level => "notice")
    Log.log(data, &blk)
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
    data = data.merge(:level => "alert")
    Log.log(data, &blk)
  end

end
