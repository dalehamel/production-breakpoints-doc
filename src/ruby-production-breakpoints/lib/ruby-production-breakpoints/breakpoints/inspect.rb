# frozen_string_literal: true
require 'ostruct'

module ProductionBreakpoints
  module Breakpoints
    # Inspect result of the last evaluated expression
    class Inspect < Base
      TRACEPOINT_TYPES = [Integer, String].freeze

      # FIXME!!! Could be **VERY** Unsafe
      # If inspect is allowed to be called on a method, it wil be extremely unsafe.
      # it will actually call the method a second time, which modifies the code
      # that is under observation, which is not desirable - tracing should be
      # transparent and the impact should be undected by the application
      # Idea: check disassembled iseqs at the tracepoint lines, to see
      # if they contain method calls. If they do, log an error and do not
      # permit installing the tracepoint
      # Should be safe for evaluting expressions that are not method calls,
      # as the inspection is done with a cloned binding
      def initialize(*args, &block)
        super(*args, &block)
        # Pad by one to make it match with ruby lineno
        @source_lines = [ '', File.read(@source_file).lines ].flatten
        @handler_iseqs = {}
      end

      # This handler basically re-runs the instruction to be able to examine
      # the result. For very expensive operations, this is probably a bad idea.
      # The original binding should not be modified.
      def handle(vm_tracepoint)
        return unless @tracepoint.enabled?

        lineno = vm_tracepoint.lineno

        # Ensures local variables are copied into the inspection sandbox
        local_vals = vm_tracepoint.binding.local_variables.map do |v|
          [v, vm_tracepoint.binding.local_variable_get(v)]
        end.to_h
        obj = OpenStruct.new(local_vals)
        bind = obj.instance_eval{binding}

        handler_iseq = @handler_iseqs[lineno]

        if handler_iseq.nil?
          handler_iseq = RubyVM::InstructionSequence
                                                .compile(@source_lines[lineno],
                                                         options: false)
          # FIXME - verify that there are no calls to:
          # opt_send_without_block, or send_with_block and any other messaging
          @handler_iseqs[vm_tracepoint.lineno] = handler_iseq
        end

        val = handler_iseq.eval(bind)
        @tracepoint.fire(lineno, val.inspect)
      end
    end
  end
end
