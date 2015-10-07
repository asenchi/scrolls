require_relative "test_helper"

class TestScrollsParser < Test::Unit::TestCase
  include Scrolls::Parser

  def test_parse_floats
    data = { elapsed: 12.00000, __time: 0 }
    assert_equal({ :elapsed => "12.000", :__time => 0 }, parse(data))
  end

  def test_parse_time
    time = Time.new(2012, 06, 19, 16, 02, 35, "+01:00")
    data = { t: time }
    assert_equal({ :t => "2012-06-19T16:02:35+01:00" }, parse(data))
  end
end
