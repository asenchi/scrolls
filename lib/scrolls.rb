require "thread"
require "scrolls/atomic"
require "scrolls/log"
require "scrolls/version"

module Scrolls
  extend self

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

  # Public: Get or set a global context that prefixs all logs
  #
  # data - A hash of key/values to prepend to each log
  #
  def global_context(data=nil)
    if data
      Log.global_context = data
    else
      Log.global_context
    end
  end

  def add_global_context(data)
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
  #   at=start
  #   inner block
  #   at=finish elapsed=0.000
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

end
