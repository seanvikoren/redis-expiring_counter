# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redis-expiring_counter/version"

Gem::Specification.new do |s|
  s.name        = "redis-expiring_counter"
  s.version     = RedisExpiringCounter::VERSION
  s.authors     = ["Sean Vikoren"]
  s.email       = ["sean@vikoren.com"]
  s.homepage    = "https://github.com/seanvikoren/redis-expiring_counter"
  s.summary     = %q{redis-expiring_counter is a fast and accurate rate limiting counter.}
  s.description = %q{The redis-expiring_counter gem builds a counter on top of redis providing fast and accurate rate limiting counters.}

  s.rubyforge_project = "redis-expiring_counter"

  s.files         = Dir.glob("lib/**/*.rb")
  #s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # dependencies
  #s.add_development_dependency "rake-compiler"
  s.add_runtime_dependency "redis"
end
