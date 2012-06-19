# The result of issues with an update I made to Scrolls. After talking with
# Fabio Kung about a fix I started work on an atomic object, but he added some
# fixes to #context without it and then used Headius' atomic gem.
#
# The code below is the start and cleanup of my atomic object. It's slim on
# details and eventually cleaned up around inspiration from Headius' code.
#
# LICENSE: Apache 2.0
#
# See Headius' atomic gem here:
# https://github.com/headius/ruby-atomic

require 'thread'

class AtomicObject
  def initialize(o)
    @mtx = Mutex.new
    @o = o
  end

  def get
    @mtx.synchronize { @o }
  end

  def set(n)
    @mtx.synchronize { @o = n }
  end

  def verify_set(o, n)
    return false unless @mtx.try_lock
    begin
      return false unless @o.equal? o
      @o = n
    ensure
      @mtx.unlock
    end
  end
end

class Atomic < AtomicObject
  def initialize(v=nil)
    super(v)
  end

  def value
    self.get
  end

  def value=(v)
    self.set(v)
    v
  end

  def update
    true until self.verify_set(o = self.get, n = yield(o))
    n
  end
end
