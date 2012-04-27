require "scrolls/version"
require "scrolls/log"

module Scrolls
  extend self

  def log(data, &blk)
    Log.log(data, &blk)
  end

  def log_exception(data, e)
    Log.log_exception(data, e)
  end

  def global_context(data)
    Log.global_context = data
  end

  def context(data, &blk)
    Log.with_context(data, &blk)
  end

end

