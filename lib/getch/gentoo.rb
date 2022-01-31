# frozen_string_literal: true

require_relative 'gentoo/bootloader'
require_relative 'gentoo/sources'
require_relative 'gentoo/boot'
require_relative 'gentoo/use'
require_relative 'gentoo/use_flag'

module Getch
  module Gentoo
    class Main
      def initialize
      end

      def bootloader
        return if STATES[:gentoo_bootloader]

        bootloader = Getch::Gentoo::Bootloader.new
        bootloader.start
        @state.bootloader
      end

      def boot
        boot = Getch::Gentoo::Boot.new
        boot.start
      end
    end
  end
end

require_relative 'gentoo/tarball'
require_relative 'gentoo/pre_config'
require_relative 'gentoo/update'
require_relative 'gentoo/post_config'
require_relative 'gentoo/terraform'
