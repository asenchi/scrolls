require "thread"
require "scrolls/atomic"
require "scrolls/log"
require "scrolls/version"

module Scrolls
  extend self

  def log(data, &blk)
    Log.log(data, &blk)
  end

  def log_exception(data, e)
    Log.log_exception(data, e)
  end

  def stream=(out)
    Log.stream=(out)
  end

  def stream
    Log.stream
  end

  def time_unit=(unit)
    Log.time_unit=(unit)
  end

  def time_unit
    Log.time_unit
  end
end
