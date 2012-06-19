require_relative "test_helper"

class TestScrollsParser < Test::Unit::TestCase
  include Scrolls::Parser
  
  def test_parse_bool
    data = { test: true, exec: false }
    assert_equal "test=true exec=false", unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect
  end

  def test_parse_numbers
    data = { elapsed: 12.00000, __time: 0 }
    assert_equal "elapsed=12.000 __time=0", unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect
  end

  def test_parse_strings
    # Strings are all double quoted, with " or \ escaped
    data = { s: "echo 'hello' \"world\"" }
    assert_equal 's="echo \'hello\' \\"world\\""', unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    data = { s: "hello world" }
    assert_equal 's="hello world"', unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    data = { s: "slasher\\" }
    assert_equal 's="slasher\\\\"', unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    # simple value is unquoted
    data = { s: "hi" }
    assert_equal 's=hi', unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect
  end

  def test_parse_constants
    data = { s1: :symbol, s2: Scrolls }
    assert_equal "s1=symbol s2=Scrolls", unparse(data)
  end

  def test_parse_time
    data = { t: Time.at(1340118155) }
    assert_equal "t=2012-06-19T11:02:35-0400", unparse(data)
  end

  def test_parse_nil
    data = { n: nil }
    assert_equal "n=nil", unparse(data)
  end
end
