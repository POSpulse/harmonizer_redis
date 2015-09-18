# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'harmonizer_redis/version'

Gem::Specification.new do |spec|
  spec.name          = "harmonizer_redis"
  spec.version       = HarmonizerRedis::VERSION
  spec.authors       = ["Tian Wang"]
  spec.email         = ["twang95@stanford.edu"]

  spec.summary       = %q{Harmonizes records}
  spec.description   = %q{Harmonizes records based on fuzzy string/phrase matching. Built on redis for speed}
  spec.homepage      = "https://github.com/POSpulse/harmonizer_redis"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "redis"
  spec.add_dependency "hiredis"
  spec.add_dependency "activesupport"
  spec.extensions    = ["ext/white_similarity/extconf.rb"]

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
