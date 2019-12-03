# frozen_string_literal: true

require 'logger'

require 'ruby-static-tracing'

require 'ruby-production-breakpoints/version'
require 'ruby-production-breakpoints/configuration'
require 'ruby-production-breakpoints/parser'
require 'ruby-production-breakpoints/breakpoints'

module ProductionBreakpoints
  extend self

  BaseError = Class.new(StandardError)
  InternalError = Class.new(BaseError)

  attr_accessor :logger, :installed_breakpoints, :config_path

  self.logger = Logger.new(STDERR)
  self.installed_breakpoints = {} # FIXME: namespace by provider, to allow multiple BP per file
  self.config_path = '/tmp/prod_bp_config' # How to handle multiple?

  # For now add new types here
  def install_breakpoint(type, source_file, start_line, end_line, trace_id: 1)
    # Hack to check if there is a supported breakpoint of this type for now
    case type.name
    when 'ProductionBreakpoints::Breakpoints::Latency'
    when 'ProductionBreakpoints::Breakpoints::Inspect'
    when 'ProductionBreakpoints::Breakpoints::Locals'
    when 'ProductionBreakpoints::Breakpoints::Ustack'
      # logger.debug("Creating latency tracer")
      # now rewrite source to call this created breakpoint through parser
    else
      logger.error("Unsupported breakpoint type #{type}")
    end

    breakpoint = type.new(source_file, start_line, end_line, trace_id: trace_id)
    installed_breakpoints[trace_id.to_sym] = breakpoint
    breakpoint.install
    breakpoint.load
  end

  def disable_breakpoint(trace_id)
    breakpoint = installed_breakpoints.delete(trace_id.to_sym)
    breakpoint.unload
    breakpoint.uninstall
  end

  def disable!
    installed_breakpoints.each do |trace_id, _bp|
      disable_breakpoint(trace_id.to_sym)
    end
  end

  def sync!
    # FIXME: don't just install, also remove - want to 'resync'
    # logger.debug("Resync initiated")
    desired = Configuration.instance.config['breakpoints']

    desired_trace_ids = desired.map { |bp| bp['trace_id'] }
    installed_trace_ids = installed_breakpoints.keys

    to_install_tids = desired_trace_ids - installed_trace_ids
    to_remove_tids = installed_trace_ids - desired_trace_ids
    to_install = desired.select { |bp| to_install_tids.include?(bp['trace_id']) }
    # logger.debug("Will install #{to_install.size} breakpoints")
    # logger.debug("Will remove #{to_remove_tids.size} breakpoints")

    to_install.each do |bp|
      handler = breakpoint_constant_for_type(bp)
      install_breakpoint(handler, bp['source_file'], bp['start_line'], bp['end_line'], trace_id: bp['trace_id'])
    end

    to_remove_tids.each do |trace_id|
      disable_breakpoint(trace_id)
    end
  end

  private

  def breakpoint_constant_for_type(bp)
    symstr = "ProductionBreakpoints::Breakpoints::#{bp['type'].capitalize}"
    type = Object.const_get(symstr)
  rescue NameError
    ProductionBreakpoints.logger.error("Could not find breakpoint handler for #{symstr}")
  end
end
