# -*- encoding: utf-8 -*-
require File.expand_path('../lib/scrolls/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Curt Micol"]
  gem.email         = ["asenchi@asenchi.com"]
  gem.description   = %q{Logging, easier, more consistent.}
  gem.summary       = %q{When do we log? All the time.}
  gem.homepage      = "https://github.com/asenchi/scrolls"
  gem.license       = 'MIT'
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "scrolls"
  gem.require_paths = ["lib"]
  gem.version       = Scrolls::VERSION
end
