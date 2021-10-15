require File.expand_path("../test_helper", __FILE__)

class TestScrollsParser < Minitest::Test
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

    data = { s: 'echo "hello"' }
    assert_equal "s='echo \"hello\"'", unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    data = { s: "hello world" }
    assert_equal 's="hello world"', unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    data = { s: "hello world".inspect }
    assert_equal "s='\"hello world\"'", unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    data = { s: "hello=world".inspect }
    assert_equal "s='\"hello=world\"'", unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    data = { s: "slasher \\" }
    assert_equal 's="slasher \\\\"', unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    data = {s: "x=4,y=10" }
    assert_equal 's="x=4,y=10"', unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    data = {s: "x=4, y=10" }
    assert_equal 's="x=4, y=10"', unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    data = {s: "x:y" }
    assert_equal 's="x:y"', unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    data = {s: "x,y" }
    assert_equal 's="x,y"', unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect

    # simple value is unquoted
    data = { s: "hi" }
    assert_equal 's=hi', unparse(data)
    assert_equal data.inspect, parse(unparse(data)).inspect
  end

  def test_unparse_constants
    data = { s1: :symbol, s2: Scrolls }
    assert_equal "s1=symbol s2=Scrolls", unparse(data)
  end

  def test_unparse_nil
    data = { n: nil }
    assert_equal "n=nil", unparse(data)
  end

  def test_unparse_time
    time = Time.new(2012, 06, 19, 16, 02, 35, "+01:00")
    data = { t: time }
    assert_equal 't="2012-06-19T16:02:35+01:00"', unparse(data)
  end

  def test_unparse_escape_keys
    html  = "<p>p</p>"
    slash = "p/p"

    data = { html => "d", slash => "d" }
    assert_equal '&lt;p&gt;p&lt;&#x2F;p&gt;=d p&#x2F;p=d',
      unparse(data, escape_keys=true)
  end

  def test_unparse_strict_logfmt
    data = { s: 'echo "hello"' }
    assert_equal 's="echo \"hello\""', unparse(data, escape_keys=false, strict_logfmt=true)
    assert_equal data.inspect, parse(unparse(data, escape_keys=false, strict_logfmt=true)).inspect
  end

  def test_parse_time
    time = Time.new(2012, 06, 19, 16, 02, 35, "+01:00")
    string = "t=2012-06-19T16:02:35+01:00"
    data = parse(string)
    assert_equal time, data[:t]
  end

end
