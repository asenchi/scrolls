require "minitest/autorun"
require "minitest/reporters"
require "stringio"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

$: << File.expand_path("../../lib", __FILE__)

require "scrolls"
