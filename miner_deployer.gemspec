# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'miner_deployer/version'

Gem::Specification.new do |spec|
  spec.name          = "miner_deployer"
  spec.version       = MinerDeployer::VERSION
  spec.authors       = ["Halan Pinheiro"]
  spec.email         = ["halan.pinheiro@codeminer42.com"]

  spec.summary       = %q{Simple solution to deploy Codeminer42 projects}
  spec.description   = %q{Simple solution to deploy Codeminer42 projects}
  spec.homepage      = "https://github.com/Codeminer42/miner_deployer"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
