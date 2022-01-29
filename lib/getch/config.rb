# frozen_string_literal: true

require 'nito'
require_relative 'config/gentoo'
require_relative 'config/void'

CONFIG_LOAD = {
  gentoo: Getch::Config::Gentoo,
  void: Getch::Config::Void
}.freeze

module Getch
  module Config
    class Main
      include NiTo

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

      def sysctl
        pwd = File.expand_path(File.dirname(__FILE__))
        dest = "#{Getch::MOUNTPOINT}/etc/sysctl.d/"

        mkdir dest
        Helpers.cp("#{pwd}/../../assets/network-stack.conf", dest)
        Helpers.cp("#{pwd}/../../assets/system.conf", dest)
      end

      def shell
        @load.shell
      end
    end
  end
end

require_relative 'config/portage'
require_relative 'config/locale'
require_relative 'config/pre_network'
require_relative 'config/keymap'
