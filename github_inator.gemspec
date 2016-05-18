# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'github_inator/version'

Gem::Specification.new do |spec|
  spec.name          = "github_inator"
  spec.version       = GithubInator::VERSION
  spec.authors       = ["nmusaelian-rally"]
  spec.email         = ["nmusaelian@rallydev.com"]

  spec.summary       = %q{talk to github api}
  spec.description   = %q{talk to github api}
  spec.homepage      = ""
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files`.split($\)
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "inator", "= 0.0.7"

  spec.add_development_dependency "bundler",  "~> 1.11"
  spec.add_development_dependency "rake",     "~> 10.0"
  spec.add_development_dependency "rspec",    "~>3.4"
end
