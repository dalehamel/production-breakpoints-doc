# frozen_string_literal: true

module ProductionBreakpoints
  module Breakpoints
    # Show local variables and their values
    class Ustack < Base
      TRACEPOINT_TYPES = [String, String, String,
                          String, String, String].freeze
      MAX_STACK_STR_SIZE = MAX_USDT_STR_SIZE * TRACEPOINT_TYPES.size

      def initialize(*args, &block)
        super(*args, &block)
        get_ruby_stack_str = <<-EOS
        caller.map { |l| l.split(":in ") }.to_h
        EOS
        @handler_iseq = RubyVM::InstructionSequence.compile(get_ruby_stack_str)
      end

      def handle(vm_tracepoint)
        return unless @tracepoint.enabled?

        stack_map = @handler_iseq.eval(vm_tracepoint.binding)

        shortened_map = {}
        stack_map.each do |k,v|
          newkey = k
          #if k.include?('gems')
          #  newkey = k[k.rindex('gems')..-1].split(File::SEPARATOR)[1..-1]
          #                                .join(File::SEPARATOR)
          #elsif k.include?('lib')
          #  newkey = k[k.rindex('lib')..-1].split(File::SEPARATOR)[1..-1]
          #                                .join(File::SEPARATOR)
          #end
          # FIXME lots of context is lost this way, as the above methods
          # consistently exceed the max size.
          # Need to find a more optimal way to shorten the stack here, to
          # pack it into the 1200 bytes available
          newkey = File.basename(k)
          shortened_map[newkey] = v
        end
        # ProductionBreakpoints.logger.debug(shortened_map.inspect)

        stack_str = shortened_map.to_json

        if stack_str.size > (MAX_STACK_STR_SIZE)
          ProductionBreakpoints.logger.error("Stack exceeds #{MAX_STACK_STR_SIZE}")
          # Truncate because i'm lazy
          stack_str = stack_str[0..MAX_STACK_STR_SIZE]
        end

        slices = stack_str.chars.each_slice(MAX_USDT_STR_SIZE).map(&:join)

        case slices.size

        when 1
          @tracepoint.fire(slices[0], "", "", "", "", "")
        when 2
          @tracepoint.fire(slices[0], slices[1], "", "", "", "")
        when 3
          @tracepoint.fire(slices[0], slices[1], slices[2], "", "", "")
        when 4
          @tracepoint.fire(slices[0], slices[1], slices[2], slices[3], "", "")
        when 5
          @tracepoint.fire(slices[0], slices[1], slices[2], slices[3],
                           slices[4], "")
        when 6
          @tracepoint.fire(slices[0], slices[1], slices[2], slices[3],
                           slices[4], slices[5])

        end
      end
    end
  end
end
