require_relative "test_helper"

class TestScrolls < Test::Unit::TestCase
  def setup
    @out = StringIO.new
    Scrolls.stream = @out
  end

  def teardown
    Scrolls.global_context({})
    # Reset our syslog context
    Scrolls.facility = Scrolls::LOG_FACILITY
    Scrolls.stream.close if Scrolls.stream.respond_to?(:close)
  end

  # def test_construct
  #   assert_equal StringIO, Scrolls.stream.class
  # end

  def test_default_global_context
    assert_equal Hash.new, Scrolls.global_context
  end

  def test_setting_global_context
    Scrolls.global_context(:g => "g")
    Scrolls.log(:d => "d")
    assert_equal "g=g d=d\n", @out.string
  end
  
  def test_adding_to_global_context
    Scrolls.global_context(:g => "g")
    Scrolls.add_global_context(:h => "h")
    Scrolls.log(:d => "d")
    assert_equal "g=g h=h d=d\n", @out.string
  end

  def test_default_context
    Scrolls.log(:data => "d")
    assert_equal Hash.new, Scrolls::Log.context
  end

  def test_setting_context
    Scrolls.context(:c =>"c") { Scrolls.log(:i => "i") }
    output = "c=c i=i\n"
    assert_equal output, @out.string
  end

  def test_all_the_contexts
    Scrolls.global_context(:g => "g")
    Scrolls.log(:o => "o") do
      Scrolls.context(:c => "c") do
        Scrolls.log(:ic => "i")
      end
      Scrolls.log(:i => "i")
    end
    @out.truncate(37)
    output = "g=g o=o at=start\ng=g c=c ic=i\ng=g i=i"
    assert_equal output, @out.string
  end

  def test_deeply_nested_context
    Scrolls.log(:o => "o") do
      Scrolls.context(:c => "c") do
        Scrolls.log(:ic => "i")
      end
      Scrolls.log(:i => "i")
    end
    @out.truncate(21)
    output = "o=o at=start\nc=c ic=i"
    assert_equal output, @out.string
  end

  def test_deeply_nested_context_dropped
    Scrolls.log(:o => "o") do
      Scrolls.context(:c => "c") do
        Scrolls.log(:ic => "i")
      end
      Scrolls.log(:i => "i")
    end
    @out.truncate(25)
    output = "o=o at=start\nc=c ic=i\ni=i"
    assert_equal output, @out.string
  end

  def test_context_after_exception
    begin
      Scrolls.context(:c => 'c') do
        raise "Error from inside of context"
      end
      fail "Exception did not escape context block"
    rescue => e
      Scrolls.log(:o => 'o')
      assert_equal "o=o\n", @out.string
    end
  end

  def test_default_time_unit
    assert_equal "seconds", Scrolls.time_unit
  end

  def test_setting_time_unit
    Scrolls.time_unit = "milliseconds"
    assert_equal "milliseconds", Scrolls.time_unit
  end

  def test_setting_incorrect_time_unit
    assert_raise Scrolls::TimeUnitError do
      Scrolls.time_unit = "years"
    end
  end

  def test_logging
    Scrolls.log(:test => "basic")
    assert_equal "test=basic\n", @out.string
  end

  def test_logging_block
    Scrolls.log(:outer => "o") { Scrolls.log(:inner => "i") }
    output = "outer=o at=start\ninner=i\nouter=o at=finish elapsed=0.000\n"
    assert_equal output, @out.string
  end

  def test_log_exception
    begin
      raise Exception
    rescue Exception => e
      Scrolls.log_exception({:test => "exception"}, e)
    end

    oneline_backtrace = @out.string.gsub("\n", 'XX')

    assert_match /test=exception at=exception.*test_log_exception.*XX.*minitest/,
      oneline_backtrace
  end

  def test_syslog_integration
    Scrolls.stream = 'syslog'
    assert_equal Scrolls::SyslogLogger, Scrolls.stream.class
  end

  def test_syslog_facility
    Scrolls.stream = 'syslog'
    assert_equal Syslog::LOG_USER, Scrolls.facility
  end

  def test_setting_syslog_facility
    Scrolls.facility = "local7"
    assert_equal Syslog::LOG_LOCAL7, Scrolls.facility
  end
end
