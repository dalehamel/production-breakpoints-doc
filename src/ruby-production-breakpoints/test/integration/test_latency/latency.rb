# frozen_string_literal: true

require 'ruby-production-breakpoints'
STDOUT.sync = true

class LatencyTestClass
  def poke
    a = 1
    sleep 0.5
    b = a + 1
    puts 'ouch'
  end
end

ProductionBreakpoints.config_path = 'latency_test.json'
ProductionBreakpoints.sync!

latency_test = LatencyTestClass.new

# Signal.trap('USR2') do
#  latency_test.poke
# end

loop do
  tp = ProductionBreakpoints.installed_breakpoints[:latency_test].tracepoint
  puts tp.enabled?
  latency_test.poke
  sleep 1
end
