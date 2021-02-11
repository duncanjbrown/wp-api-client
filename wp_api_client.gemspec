# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wp_api_client/version'

Gem::Specification.new do |spec|
  spec.name          = "wp-api-client"
  spec.version       = WpApiClient::VERSION
  spec.authors       = ["Duncan Brown"]
  spec.email         = ["duncanjbrown@gmail.com"]

  spec.summary       = %q{A read-only client for the WordPress REST API (v2).}
  spec.homepage      = "https://github.com/duncanjbrown/wp-api-client"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.3'

  spec.add_dependency "faraday", "~> 0.9"
  spec.add_dependency "faraday_middleware", "~> 0.10"
  spec.add_dependency "faraday-http-cache", "~> 1.2"
  spec.add_dependency "simple_oauth", "~> 0.3"
  spec.add_dependency "typhoeus", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 3"
  spec.add_development_dependency "webmock", "~> 3"
end
