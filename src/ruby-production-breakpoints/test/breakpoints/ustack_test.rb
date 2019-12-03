require 'test_helper'

module ProductionBreakpoints
  class UstackTest < ProductionBreakpointsTest

    def setup
      @start_line = 10
      @end_line = 11
      @trace_id = :ustack_test
      @source_file = ruby_source_testfile_path('ustack_target.rb')
      require @source_file
      ProductionBreakpoints.install_breakpoint(ProductionBreakpoints::Breakpoints::Ustack,
                                               @source_file, @start_line, @end_line,
                                               trace_id: @trace_id)
    end

    # FIXME uses linux-specific code, should separate for portability
    #def test_install_breakpoint
    #  assert(ProductionBreakpoints::MyUstackClass.instance_methods.include?(:some_method))

    #  assert(2, c.some_method)

    #  c.sleep_loop(60)
    #end

    def test_elf_notes
      breakpoint = ProductionBreakpoints.installed_breakpoints[@trace_id]

      #c = ProductionBreakpoints::MyUstackClass.new
      #c.sleep_loop(60)

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
