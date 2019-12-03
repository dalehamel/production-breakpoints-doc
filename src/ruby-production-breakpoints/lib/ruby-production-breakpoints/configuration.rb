# frozen_string_literal: true

require 'json'

module ProductionBreakpoints
  class Configuration
    # Modes of operation for tracers
    module Modes
      ON = 'ON'
      OFF = 'OFF'
      SIGNAL = 'SIGNAL'

      module SIGNALS
        SIGURG = 'URG'
      end
    end

    class << self
      def instance
        @instance ||= new
      end
    end

    attr_reader :mode, :signal, :config

    # A new configuration instance
    def initialize
      @mode = Modes::SIGNAL
      @signal = Modes::SIGNALS::SIGURG
      if File.exist?(ProductionBreakpoints.config_path)
        @config = JSON.load(File.read(ProductionBreakpoints.config_path))
      else
        ProductionBreakpoints.logger.error("Config file #{ProductionBreakpoints.config_path} not found")
      end

      enable_trap
    end

    # Sets the mode [ON, OFF, SIGNAL]
    # Default is SIGNAL
    def mode=(new_mode)
      handle_old_mode
      @mode = new_mode
      handle_new_mode
    end

    # Sets the SIGNAL to listen to,
    # Default is SIGPROF
    def signal=(new_signal)
      disable_trap
      @signal = new_signal
      enable_trap
    end

    private

    # Clean up trap handlers if mode changed to not need it
    def handle_old_mode
      disable_trap if @mode == Modes::SIGNAL
    end

    # Enable trap handlers if needed
    def handle_new_mode
      if @mode == Modes::SIGNAL
        enable_trap
      elsif @mode == Modes::ON
        StaticTracing.enable!
      elsif @mode == Modes::OFF
        StaticTracing.disable!
      end
    end

    # Disables trap handler
    def disable_trap
      Signal.trap(@signal, 'DEFAULT')
    end

    # Enables a new trap handler
    def enable_trap
      # ProductionBreakpoints.logger.debug("trap handler enabled for #{@signal}")
      Signal.trap(@signal) { ProductionBreakpoints.sync! }
    end
  end
end
