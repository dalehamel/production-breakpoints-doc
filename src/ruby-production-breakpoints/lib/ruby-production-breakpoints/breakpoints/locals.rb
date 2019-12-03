# frozen_string_literal: true

require 'json'

module ProductionBreakpoints
  module Breakpoints
    # Show local variables and their values
    class Locals < Base # FIXME: refactor a bunch of these idioms into Base
      TRACEPOINT_TYPES = [String].freeze

      def handle(vm_tracepoint)
        return unless @tracepoint.enabled?

        locals = vm_tracepoint.binding.local_variables
        vals = locals.map do |v|
          [v, vm_tracepoint.binding.local_variable_get(v)]
        end.to_h
        @tracepoint.fire(vals.to_json)
      end
    end
  end
end
