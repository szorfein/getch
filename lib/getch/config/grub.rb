# frozen_string_literal: true

require 'nito'

module Getch
  module Config
    # install grub
    class Grub
      include NiTo

      def initialize
        @log = Log.new
        @disk = OPTIONS[:boot_disk] ||= OPTIONS[:disk]
        # https://wiki.archlinux.org/title/Install_Arch_Linux_on_ZFS
        @prefix = OPTIONS[:fs] == 'zfs' ? 'ZPOOL_VDEV_NAME_PATH=1' : ''
        @os_name = OPTIONS[:os].capitalize
        x
      end

      protected

      def x
        @log.info "Installing Grub on #{@disk}...\n"
        Helpers.efi? ? grub_efi : grub_bios
      end

      private

      def grub_efi
        mount_efivars
        cmd = "#{@prefix} grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=\"#{@os_name}\""
        ChrootOutput.new(cmd)
      end

      def grub_bios
        cmd = "#{@prefix} grub-install /dev/#{@disk}"
        ChrootOutput.new(cmd)
      end

      # In case where efivars is not mounted
      # avoid error with grub
      def mount_efivars
        mount '-t efivarfs', 'efivarfs', '/sys/firmware/efi/efivars'
      end
    end
  end
end
