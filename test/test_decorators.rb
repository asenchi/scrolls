require "minitest/autorun"

$:.unshift File.expand_path(File.join("..", "lib"))
require "scrolls/decorators"

class MyService
  include Scrolls::Decorators

  log_context "myservice", release: "v51"

  def only_tags
    log "only", "tags"
  end

  def basic_logging
    log "basic", "that", "works", data: "useful"
  end

  log
  def basic_wrap_with_logging
    sleep 1
  end

  log "wrap_with_more_context", rule: "always"
  def wrap_with_more_context
    sleep 1
  end

end


class TestDecorators < MiniTest::Unit::TestCase

  def setup
    @output, writer = IO.pipe
    @service = MyService.new
    Scrolls::Log.start(writer)
  end

  def test_converts_tags
    @service.only_tags
    assert_equal "myservice release=v51 only tags\n", @output.gets
  end

end

