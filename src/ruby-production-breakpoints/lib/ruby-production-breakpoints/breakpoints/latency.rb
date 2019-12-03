# frozen_string_literal: true

module ProductionBreakpoints
  module Breakpoints
    # Exposes nanosecond the latency of executing the selected lines
    class Latency < Base # FIXME: refactor a bunch of these idioms into Base
      TRACEPOINT_TYPES = [Integer].freeze

      class << self
        def start_times
          @start_times ||= {}
        end

        def start_times_set(tid, ns)
          @start_times ||= {}
          @start_times[tid] = ns
        end
      end

      def initialize(*args, &block)
        super(*args, &block)
        @trace_lines = [@start_line, @end_line]
      end

      # FIXME: I think this needs to be keyed by thread id
      # Storing @start_time as an instance variable isn't thread safe
      # as a breakpoint can apply to many classes
      def handle(vm_tracepoint)
        return unless @tracepoint.enabled?
        tid = Thread.current.object_id
        puts "Line #{vm_tracepoint.lineno}, TID #{tid} S: #{@start_line} E: #{@end_line}"
        Latency.start_times_set(tid, StaticTracing.nsec) if vm_tracepoint.lineno == @start_line

        if Latency.start_times[tid] && vm_tracepoint.lineno == @end_line
          duration = StaticTracing.nsec - Latency.start_times[tid]
          @tracepoint.fire(duration)
        else
          puts "Didn't fire for #{vm_tracepoint.lineno}"
        end
      end
    end
  end
end
