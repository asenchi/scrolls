# -*- encoding: utf-8 -*-
require File.expand_path('../lib/scrolls/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Heroku"]
  gem.email         = ["curt@heroku.com"]
  gem.description   = "Logging, easier, more consistent."
  gem.summary       = "When do we log? All the time."
  gem.homepage      = "https://github.com/asenchi/scrolls"
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "scrolls"
  gem.require_paths = ["lib"]
  gem.version       = Scrolls::VERSION
end
