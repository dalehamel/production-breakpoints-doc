# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'ruby-production-breakpoints/version'

post_install_message = <<~eof
  This is alpha quality and not suitable for production use
  ... usless you're feeling bold ;)

  If you find any bugs, please file them at:
  	github.com/shopify/ruby-production-breakpoints
eof

Gem::Specification.new do |s|
  s.name = 'ruby-production-breakpoints'
  s.version = ProductionBreakpoints::VERSION
  s.summary = 'USDT tracing for Ruby'
  s.post_install_message = post_install_message
  s.description = <<-DOC
    A Ruby C extension that enables defining static tracepoints
    from within a ruby context.
  DOC
  s.homepage = 'https://github.com/dalehamel/ruby-production-breakpoints'
  s.authors = ['Dale Hamel']
  s.email = 'dale.hamel@srvthe.net'
  s.license = 'MIT'

  s.add_dependency('ruby-static-tracing', '>= 0.0.15')
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-hooks'
  s.add_development_dependency 'minitest-reporters'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rake', '< 11.0'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov'
end
