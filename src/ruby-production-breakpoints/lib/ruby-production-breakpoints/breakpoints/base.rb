# frozen_string_literal: true

module ProductionBreakpoints
  module Breakpoints
    class Base
      # workaround for https://github.com/iovisor/bpftrace/issues/305
      MAX_USDT_STR_SIZE = 64 # see https://github.com/iovisor/bpftrace/blob/0e97b2c8f6bbc50a31d404a32000b5b2b85753b0/src/main.cpp#L337-L345
      TRACEPOINT_TYPES = [].freeze

      attr_reader :provider_name, :name, :tracepoint

      def initialize(source_file, start_line, end_line, trace_id: 1)
        @source_file = source_file
        @start_line = start_line
        @end_line = end_line
        @trace_id = trace_id
        @handler_str = self.class.name.split('::').last.downcase

        @parser = ProductionBreakpoints::Parser.new(@source_file)
        @node = @parser.find_definition_node(@start_line, @end_line)
        @ns = Object.const_get(@parser.find_definition_namespace(@node)) # FIXME: error handling, if not found
        @method_symbol = @parser.find_definition_symbol(@node)

        @provider_name = File.basename(@source_file).gsub('.', '_')
        @name = "#{@handler_str}_#{@trace_id}"
        @tracepoint = StaticTracing::Tracepoint.new(@provider_name,
                                                    @name,
                                                    *self.class.const_get('TRACEPOINT_TYPES'))
        @trace_lines = (@start_line..@end_line).to_a
        @vm_tracepoints = {}
      end

      def install
        @trace_lines.each do |line|
          puts "Adding tracepoint for #{line}"
          vm_tp = TracePoint.new(:line) do |tp|
            handle(tp)
          end
          vm_tp.enable(target: @ns.instance_method(@method_symbol),
                       target_line: line)
          @vm_tracepoints[line] = vm_tp
        end
      end

      def uninstall
        @vm_tracepoints.each_value(&:disable)
      end

      def load
        @tracepoint.provider.enable
      end

      def unload
        @tracepoint.provider.disable
      end

      # Allows for specific handling of the selected lines
      def handle(vm_tracepoint); end
    end
  end
end
