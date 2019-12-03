# frozen_string_literal: true

require 'ruby-production-breakpoints'
STDOUT.sync = true

class HelloTestClass
  def poke
    a = 1
    hello = 'Hello world'
    puts 'ouch'
  end
end

ProductionBreakpoints.config_path = 'hello_test.json'
ProductionBreakpoints.sync!

hello = HelloTestClass.new

Signal.trap('USR2') do
  hello.poke
end

loop do
  tp = ProductionBreakpoints.installed_breakpoints[:hello_test].tracepoint
  puts tp.enabled?
  sleep 1
end
