require_relative "test_helper"

class TestAtomic < Test::Unit::TestCase
  def test_construct
    atomic = Scrolls::Atomic.new
    assert_equal nil, atomic.value
    
    atomic = Scrolls::Atomic.new(0)
    assert_equal 0, atomic.value
  end
  
  def test_value
    atomic = Scrolls::Atomic.new(0)
    atomic.value = 1
    
    assert_equal 1, atomic.value
  end
  
  def test_update
    atomic = Scrolls::Atomic.new(1000)
    res = atomic.update {|v| v + 1}
    
    assert_equal 1001, atomic.value
    assert_equal 1001, res
  end

  def test_update_retries
    tries = 0
    atomic = Scrolls::Atomic.new(1000)
    atomic.update{|v| tries += 1 ; atomic.value = 1001 ; v + 1}
    assert_equal 2, tries
  end
end
