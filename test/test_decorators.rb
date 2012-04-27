require "stringio"
require "minitest/autorun"

$:.unshift File.expand_path(File.join("..", "lib"))
require "scrolls/decorators"

class TestDecorators < MiniTest::Unit::TestCase

  class MyService
    include Scrolls::Decorators

    log_context "myservice", release: "v51"

    def basic_logging
      log "basic", data: "useful"
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



end

