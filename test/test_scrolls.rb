require File.expand_path("../test_helper", __FILE__)

class TestScrolls < Test::Unit::TestCase
  def setup
    @out = StringIO.new
    Scrolls.init(
      :stream => @out
    )
  end

  def teardown
  end

  def test_construct
    assert_equal StringIO, Scrolls.stream.class
  end

  def test_default_global_context
    Scrolls.init(:stream => @out)
    assert_equal Hash.new, Scrolls.global_context
  end

  def test_setting_global_context
    Scrolls.init(
      :stream => @out,
      :global_context => {:g => "g"},
    )
    Scrolls.log(:d => "d")
    assert_equal "g=g d=d\n", @out.string
  end

  def test_default_context
    Scrolls.log(:d => "d")
    assert_equal Hash.new, Scrolls.internal.context
  end

  def test_setting_context
    Scrolls.context(:c =>"c") { Scrolls.log(:i => "i") }
    output = "c=c i=i\n"
    assert_equal output, @out.string
  end

  def test_all_the_contexts
    Scrolls.init(
      :stream => @out,
      :global_context => {:g => "g"},
    )
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
      Scrolls.log(:tu => "yrs")
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

    assert_equal 1, @out.string.scan(/.*site=.*/).size
  end

  def test_multi_line_exceptions
    Scrolls.single_line_exceptions = "multi"
    begin
      raise Exception
    rescue Exception => e
      Scrolls.log_exception({:o => "o"}, e)
    end

    oneline_backtrace = @out.string.gsub("\n", 'XX')
    assert_match /o=o at=exception.*test_multi_line_exceptions.*XX.*minitest/,
      oneline_backtrace
  end

  def test_syslog_integration
    Scrolls.stream = 'syslog'
    assert_equal Scrolls::SyslogLogger, Scrolls.internal.logger.class
  end

  def test_syslog_facility
    Scrolls.stream = 'syslog'
    assert_equal Syslog::LOG_USER, Scrolls.facility
  end

  def test_setting_syslog_facility
    Scrolls.facility = "local7"
    assert_equal Syslog::LOG_LOCAL7, Scrolls.facility
  end

  def test_setting_syslog_facility_after_instantiation
    Scrolls.stream = 'syslog'
    Scrolls.facility = 'local7'
    assert_match /facility=184/, Scrolls.internal.logger.inspect
  end

  def test_add_timestamp
    Scrolls.add_timestamp = true
    Scrolls.log(:test => "foo")
    iso8601_regexp = "(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[0-1]|0[1-9]|[1-2][0-9])T(2[0-3]|[0-1][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[0-1][0-9]):[0-5][0-9])?"
    assert_match(/^now="#{iso8601_regexp}" test=foo$/, @out.string)
  end

  def test_logging_strings
    Scrolls.log("string")
    assert_equal "log_message=string\n", @out.string
  end

  def test_default_logging_levels
    Scrolls.debug(:t => "t")
    assert_equal "", @out.string
    Scrolls.info(:t => "t")
    assert_equal "t=t level=info\n", @out.string
  end

  def test_level_translation_error
    Scrolls.error(:t => "t")
    assert_equal "t=t level=warning\n", @out.string
  end

  def test_level_translation_fatal
    Scrolls.fatal(:t => "t")
    assert_equal "t=t level=error\n", @out.string
  end

  def test_level_translation_warn
    Scrolls.warn(:t => "t")
    assert_equal "t=t level=notice\n", @out.string
  end

  def test_level_translation_unknown
    Scrolls.unknown(:t => "t")
    assert_equal "t=t level=alert\n", @out.string
  end

end
