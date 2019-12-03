require 'test_helper'

module ProductionBreakpoints
  class LocalsBreakpointTest < ProductionBreakpointsTest

    def setup
      @start_line = 7
      @end_line = 9
      @trace_id = :test_breakpoint_install
      @source_file = ruby_source_testfile_path('locals_target.rb')
      require @source_file
      ProductionBreakpoints.install_breakpoint(ProductionBreakpoints::Breakpoints::Locals,
                                               @source_file, @start_line, @end_line,
                                               trace_id: @trace_id)

    end
    # FIXME uses linux-specific code, should separate for portability
    def test_install_breakpoint
      assert(ProductionBreakpoints::MyLocalsClass.instance_methods.include?(:some_method))

      c = ProductionBreakpoints::MyLocalsClass.new
      assert(2, c.some_method)
    end


    def test_elf_notes
      breakpoint = ProductionBreakpoints.installed_breakpoints[@trace_id]

      # FIXME this is linux specific from here on
      provider_fd = find_provider_fd(breakpoint.provider_name)
      assert(provider_fd)

      elf_notes = `readelf --notes #{provider_fd}`

      assert_equal(breakpoint.provider_name,
                   elf_notes.lines.find { |l| l =~ /\s+Provider:/ }.split(/\s+/).last)


      assert_equal(breakpoint.name,
                   elf_notes.lines.find { |l| l =~ /\s+Name:/ }.split(/\s+/).last)
    end

    def teardown
      ProductionBreakpoints.disable_breakpoint(@trace_id)
    end

    def after_all
      ProductionBreakpoints.disable!
    end
  end
end
