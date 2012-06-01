require_relative "test_helper"

class TestScrolls < Test::Unit::TestCase
  def setup
    @out = StringIO.new
    Scrolls.stream = @out
  end

  def test_construct
    assert_equal StringIO, Scrolls.stream.class
  end

  def test_default_time_unit
    assert_equal "seconds", Scrolls.time_unit
  end

  def test_setting_time_unit
    Scrolls.time_unit = "milliseconds"
    assert_equal "milliseconds", Scrolls.time_unit
  end

  def test_logging
    Scrolls.log(test: "basic")
    assert_equal "test=basic\n", @out.string
  end

  def test_logging_block
    Scrolls.log(outer: "o") { Scrolls.log(inner: "i") }
    output = "outer=o at=start\ninner=i\nouter=o at=finish elapsed=0.000\n"
    assert_equal output, @out.string
  end

  def test_log_exception
    begin
      raise Exception
    rescue Exception => e
      Scrolls.log_exception({test: "exception"}, e)
    end
    @out.truncate(27)
    assert_equal "test=exception at=exception", @out.string
  end
end
