# frozen_strin_literal: true

module Getch
  module Gentoo
    class Bootloader
      def initialize
        @pkgs = []
        @class_fs = Getch.select_fs
        @config = @class_fs::Config.new
      end

      def start
        @config.fstab
        config_useflag
        dependencies
        install
        @config.cmdline
      end

      def config_useflag
      end

      # Dracut is used by sys-kernel/gentoo-kernel
      def dependencies
        @pkgs << 'app-shells/dash'
        @pkgs << 'sys-kernel/dracut'
        if Helpers.efi?
          @pkgs << 'efivar'
          @pkgs << 'sys-kernel/installkernel-systemd-boot'
        else
          @pkgs << 'sys-boot/grub:2'
          @pkgs << 'sys-kernel/installkernel-gentoo' # for Grub
        end
      end

      def install
        all_pkgs = @pkgs.join(' ')
        Getch::Emerge.new(all_pkgs).run!
      end

      def config
      end
    end
  end
end
