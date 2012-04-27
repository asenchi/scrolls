require "minitest/autorun"

$:.unshift File.expand_path(File.join("..", "lib"))
require "scrolls/decorators"

class MyService
  include Scrolls::Decorators

  log_context "myservice", release: "v51"

  def class_log_context
    log
  end

  def only_tags
    log "only", "tags"
  end

  def only_hash
    log from: "hash", size: 2
  end

  def basic_logging
    log "basic", "that", "works", data: "useful", number: 10
  end

  log
  def basic_wrap_with_logging
    sleep 0.1
  end

  log "wrap_with_more_context", rule: "always"
  def wrap_with_more_context
    sleep 0.1
  end

end


class TestDecorators < MiniTest::Unit::TestCase

  @@output, writer = IO.pipe
  Scrolls::Log.start(writer)

  def setup
    @service = MyService.new
  end

  def test_class_log_context
    @service.class_log_context
    assert_equal "myservice release=v51\n", @@output.gets
  end

  def test_converts_tags
    @service.only_tags
    assert_equal "myservice release=v51 only tags\n", @@output.gets
  end

  def test_accepts_only_hash
    @service.only_hash
    assert_equal "myservice release=v51 from=hash size=2\n", @@output.gets
  end

  def test_accepts_tags_and_hash
    @service.basic_logging
    assert_equal "myservice release=v51 basic that works data=useful number=10\n", @@output.gets
  end

  def test_wraps_method
    @service.basic_wrap_with_logging
    assert_equal "myservice release=v51 class=MyService method=basic_wrap_with_logging at=start\n", @@output.gets
    assert_includes @@output.gets, "myservice release=v51 class=MyService method=basic_wrap_with_logging at=finish elapsed=0.1"
  end

  def test_wraps_method_with_context
    @service.wrap_with_more_context
    assert_equal "myservice release=v51 wrap_with_more_context rule=always class=MyService method=wrap_with_more_context at=start\n", @@output.gets
    assert_includes @@output.gets, "myservice release=v51 wrap_with_more_context rule=always class=MyService method=wrap_with_more_context at=finish elapsed=0.1"
  end

end

