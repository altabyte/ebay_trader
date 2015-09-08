# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ebay_trader/version'

Gem::Specification.new do |spec|
  spec.name          = 'ebay-trader'
  spec.version       = EbayTrader::VERSION
  spec.authors       = ['Rob Graham']
  spec.email         = ['rob@altabyte.com']

  spec.summary       = %q{A lightweight easy to use Ruby gem for interacting with eBay's Trading API.}
  spec.description   = <<-DESC
    A lightweight easy to use Ruby gem for interacting with eBay's Trading API.
    Using its simple DSL you can quickly and intuitively post XML requests to eBay and rapidly interpret the responses.
  DESC
  spec.homepage      = 'https://github.com/altabyte/ebay_trader'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',    '~> 1.10'
  spec.add_development_dependency 'rake',       '~> 10.0'
  spec.add_development_dependency 'rspec'

  spec.add_runtime_dependency 'activesupport',  '~> 4.0'
  spec.add_runtime_dependency 'ox',             '~> 2.2'

  # Uncomment the following line to have monetary values cast to Money types...
  # spec.add_runtime_dependency 'money'
end
