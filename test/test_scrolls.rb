require File.expand_path("../test_helper", __FILE__)

class TestScrolls < Minitest::Test
  def setup
    @out = StringIO.new
    Scrolls.init(
      :stream => @out
    )
  end

  def test_default_construct
    Scrolls.init
    assert_equal Scrolls::IOLogger, Scrolls.logger.class
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
    rescue
      Scrolls.log(:o => 'o')
      assert_equal "o=o\n", @out.string
    end
  end

  def test_deeply_nested_context_after_exception
    Scrolls.log(:o => "o") do
      begin
        Scrolls.log(:io => 'io') do
          raise "Error from inside of nested logging"
        end
      rescue
        Scrolls.log(:o => 'o')
      end
    end
    @out.truncate(124)
    output = "o=o at=start\nio=io at=start\nio=io at=exception reraise=true class=RuntimeError message=\"Error from inside of nested logging\""
    assert_equal output, @out.string
  end

  def test_default_time_unit
    assert_equal "seconds", Scrolls.time_unit
  end

  def test_setting_time_unit
    Scrolls.time_unit = "milliseconds"
    assert_equal "milliseconds", Scrolls.time_unit
  end

  def test_setting_incorrect_time_unit
    assert_raises Scrolls::TimeUnitError do
      Scrolls.time_unit = "years"
      Scrolls.log(:tu => "yrs")
    end
  end

  def test_unknown_log_level
    assert_raises Scrolls::LogLevelError do
      Scrolls.log(:level => "nope")
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
      Scrolls.log_exception(e, {:test => "exception"})
    end

    oneline_bt = @out.string.gsub("\n", 'XX')
    assert_match(/test=exception at=exception.*test_log_exception.*XX/, oneline_bt)
  end

  def test_multi_line_exceptions
    Scrolls.single_line_exceptions = "multi"
    begin
      raise Exception
    rescue Exception => e
      Scrolls.log_exception(e, {:o => "o"})
    end

    oneline_bt = @out.string.gsub("\n", 'XX')
    assert_match(/o=o at=exception.*test_multi_line_exceptions.*XX/, oneline_bt)
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
    assert_match(/facility=184/, Scrolls.internal.logger.inspect)
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

  def test_sending_string_error
    Scrolls.error("error")
    assert_equal "log_message=error\n", @out.string
  end

  def test_sending_string_fatal
    Scrolls.fatal("fatal")
    assert_equal "log_message=fatal\n", @out.string
  end

  def test_sending_string_warn
    Scrolls.warn("warn")
    assert_equal "log_message=warn\n", @out.string
  end

  def test_sending_string_unknown
    Scrolls.unknown("unknown")
    assert_equal "log_message=unknown\n", @out.string
  end

end
