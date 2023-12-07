# frozen_string_literal: true

require 'nito'

module Getch
  module Gentoo
    # Configure system after install the base system (when chroot is available)
    class PostConfig
      include NiTo

      def initialize
        @make = "#{OPTIONS[:mountpoint]}/etc/portage/make.conf"
        x
      end

      protected

      def x
        Getch::Config::Locale.new
        Getch::Config::Keymap.new
        Getch::Config::TimeZone.new
        cpuflags
        Gentoo::UseFlag.new
        grub
      end

      private

      def cpuflags
        conf = "#{OPTIONS[:mountpoint]}/etc/portage/package.use/00cpuflags"
        Install.new('app-portage/cpuid2cpuflags')
        cpuflags = Chroot.new('cpuid2cpuflags')
        File.write(conf, "*/* #{cpuflags}\n")
      end

      def grub
        grub_pc = Helpers.efi? ? 'GRUB_PLATFORMS="efi-64"' : 'GRUB_PLATFORMS="pc"'
        echo_a "#{OPTIONS[:mountpoint]}/etc/portage/make.conf", grub_pc
      end
    end
  end
end
