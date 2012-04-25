require "stringio"
require "minitest/autorun"

$: << "../lib"
require "scrolls"

class TestScrollsParser < MiniTest::Unit::TestCase
  def test_unparse_tags
    data = {:test => true, :tag => true}
    assert "test tag" == Scrolls::Log.unparse(data)
  end

  def test_unparse_strings
    data = {:test => "strings"}
    assert "test=strings" == Scrolls::Log.unparse(data)

    data = {:s => "echo 'hello' \"world\""}
    assert 's="echo \'hello\' ..."' == Scrolls::Log.unparse(data)

    data = {:s => "hello world"}
    assert 's="hello world"' == Scrolls::Log.unparse(data)

    data = {:s => "hello world\\"}
    assert 's="hello world\"' == Scrolls::Log.unparse(data)
  end

  def test_unparse_floats
    data = {:test => 0.3}
    assert "test=0.300" == Scrolls::Log.unparse(data)
  end
end
