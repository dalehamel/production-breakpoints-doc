# frozen_string_literal: true

require 'ruby-production-breakpoints'
STDOUT.sync = true

class UstackTestClass
  def poke
    a = 1
    puts 'ouch'
  end
end

ProductionBreakpoints.config_path = 'ustack_test.json'
ProductionBreakpoints.sync!

ustack_test = UstackTestClass.new

Signal.trap('USR2') do
  ustack_test.poke
end

loop do
  tp = ProductionBreakpoints.installed_breakpoints[:ustack_test].tracepoint
  puts tp.enabled?
  sleep 1
end
