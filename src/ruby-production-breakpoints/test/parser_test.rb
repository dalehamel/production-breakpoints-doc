require 'test_helper'

module ProductionBreakpoints
  class ParserTest < ProductionBreakpointsTest


    def test_find_known_method_symbol
      start_line = 28
      end_line = 29
      source_file = ruby_source_testfile_path('ruby-static-tracing.rb')
      parser = ProductionBreakpoints::Parser.new(source_file)

      def_node = parser.find_definition_node(start_line, end_line)
      def_name = parser.find_definition_symbol(def_node)
      assert(def_name == :issue_disabled_tracepoints_warning)
    end

    def test_find_definition_node
      start_line = 28
      end_line = 29
      source_file = ruby_source_testfile_path('ruby-static-tracing.rb')
      parser = ProductionBreakpoints::Parser.new(source_file)

      def_node = parser.find_definition_node(start_line, end_line)
      assert(def_node.type == :DEFN)
      assert(start_line >= def_node.first_lineno)
      assert(end_line <= def_node.last_lineno)
    end

    def test_find_definition_namespace
      start_line = 7
      end_line = 8
      source_file = ruby_source_testfile_path('breakpoint_target.rb')
      require source_file
      assert(ProductionBreakpoints::MyClass.instance_methods.include?(:some_method))

      parser = ProductionBreakpoints::Parser.new(source_file)

      def_node = parser.find_definition_node(start_line, end_line)

      ns = Object.const_get(parser.find_definition_namespace(def_node))

      assert_equal(ProductionBreakpoints::MyClass, ns)
    end

    def after_all
      ProductionBreakpoints.disable!
    end
  end
end
