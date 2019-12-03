# frozen_string_literal: true

module ProductionBreakpoints
  # FIXME: this class is a mess, figure out interface and properly separate private / public
  class Parser
    attr_reader :root_node

    def initialize(source_file)
      @root_node = RubyVM::AbstractSyntaxTree.parse_file(source_file)
      @source_lines = File.read(source_file).lines
      @logger = ProductionBreakpoints.logger
    end

    # FIXME: set a max depth here to pretent unbounded recursion? probably should
    def find_node(node, type, first, last, depth: 0)
      child_nodes = node.children.select { |c| c.is_a?(RubyVM::AbstractSyntaxTree::Node) }
      # @logger.debug("D: #{depth} #{node.type} has #{child_nodes.size} children and spans #{node.first_lineno}:#{node.first_column} to #{node.last_lineno}:#{node.last_column}")

      if node.type == type && first >= node.first_lineno && last <= node.last_lineno
        return node
      end

      child_nodes.map { |n| find_node(n, type, first, last, depth: depth + 1) }.flatten
    end

    def find_lineage(target)
      lineage = _find_lineage(@root_node, target)
      lineage.pop # FIXME: verify leafy node is equal to target or throw an error?
      lineage
    end

    def find_definition_namespace(target)
      lineage = find_lineage(target)

      namespaces = []
      lineage.each do |n|
        next unless n.type == :MODULE || n.type == :CLASS

        symbols = n.children.select { |c| c.is_a?(RubyVM::AbstractSyntaxTree::Node) && c.type == :COLON2 }
        if symbols.size != 1
          @logger.error("Couldn't determine symbol location for parent namespace")
        end
        symbol = symbols.first

        symstr = @source_lines[symbol.first_lineno - 1][symbol.first_column..symbol.last_column].strip
        namespaces << symstr
      end

      namespaces.join('::')
    end

    def find_definition_symbol(def_node)
      def_column_start = def_node.first_column
      def_column_end = _find_args_start(def_node).first_column
      @source_lines[def_node.first_lineno - 1][(def_column_start + 3 + 1)..def_column_end].strip.to_sym
    end

    def find_definition_node(start_line, end_line)
      _find_definition_node(@root_node, start_line, end_line)
    end

    private

    def _find_lineage(node, target, depth: 0)
      child_nodes = node.children.select { |c| c.is_a?(RubyVM::AbstractSyntaxTree::Node) }
      # @logger.debug("D: #{depth} #{node.type} has #{child_nodes.size} children and spans #{node.first_lineno}:#{node.first_column} to #{node.last_lineno}:#{node.last_column}")

      if node.type == target.type &&

         target.first_lineno >= node.first_lineno &&
         target.last_lineno <= node.last_lineno
        return [node]
      end

      parents = []
      child_nodes.each do |n|
        res = _find_lineage(n, target, depth: depth + 1)
        unless res.empty?
          res.unshift(n)
          parents = res
        end
      end

      parents.flatten
    end

    # FIXME: better error handling
    def _find_definition_node(node, start_line, end_line)
      defs = find_node(node, :DEFN, start_line, end_line)

      if defs.size > 1
        @logger.error('WHaaat? Multiple definitions found?! Bugs will probably follow')
      end
      defs.first
    end

    # FIXME: better error handling
    def _find_args_start(def_node)
      args = find_node(def_node, :ARGS, def_node.first_lineno, def_node.first_lineno)

      if args.size > 1
        @logger.error("I didn't think this was possible, I must have been wrong")
      end
      args.first
    end
  end
end
