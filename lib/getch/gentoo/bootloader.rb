# frozen_strin_literal: true

module Getch
  module Gentoo
    class Bootloader
      def initialize
        @pkgs = []
        @class_fs = Getch.select_fs
        @config = @class_fs::Config.new
        @disk = Getch::OPTIONS[:boot_disk] ?
          Getch::OPTIONS[:boot_disk] :
          Getch::OPTIONS[:disk]
        @esp = '/efi'
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
        Getch::Emerge.new(all_pkgs).pkg!
      end

      def setup
        if Helpers.efi?
          Getch::Chroot.new("bootctl --path #{@esp} install").run!
        else
          Getch::Chroot.new("grub-install /dev/#{@disk}").run!
        end
      end

      def update
        Getch::Emerge.new('--config sys-kernel/gentoo-kernel').pkg!
        if Helpers.efi?
          puts ' => Updating systemd-boot...'
          Getch::Chroot.new("bootctl --path #{@esp} update").run!
        else
          puts ' => Updating grub...'
          Getch::Chroot.new('grub-mkconfig -o /boot/grub/grub.cfg').run!
        end
      end

      def config
      end
    end
  end
end
