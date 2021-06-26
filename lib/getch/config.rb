require_relative 'config/gentoo'
require_relative 'config/void'

CONFIG_LOAD = {
  gentoo: Getch::Config::Gentoo,
  void: Getch::Config::Void
}.freeze

module Getch
  module Config
    class Main
      def initialize
        os = OPTIONS[:os].to_sym
        @load = CONFIG_LOAD[os].new
      end

      def ethernet
        @load.ethernet
      end

      def dns
        @load.dns
      end

      def wifi
        @load.wifi
      end
    end
  end
end
