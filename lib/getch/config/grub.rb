# frozen_string_literal: true

module Getch
  module Config
    class Grub
      def initialize
        @log = Log.new
        @disk = OPTIONS[:boot_disk] ||= OPTIONS[:disk]
        # https://wiki.archlinux.org/title/Install_Arch_Linux_on_ZFS
        @prefix = OPTIONS[:fs] == 'zfs' ? 'ZPOOL_VDEV_NAME_PATH=1' : ''
        @os_name = OPTIONS[:os].capitalize
        x
      end

      def x
        @log.info "Installing Grub on #{@disk}...\n"
        Helpers.efi? ? grub_efi : grub_bios
      end 

      private

      def grub_efi
        cmd = "#{@prefix} grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=\"#{@os_name}\""
        ChrootOutput.new(cmd)
      end

      def grub_bios
        cmd = "#{@prefix} grub-install /dev/#{@disk}"
        ChrootOutput.new(cmd)
      end
    end
  end
end
