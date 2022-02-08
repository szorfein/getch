# frozen_string_literal: true

module Getch
  module Gentoo
    class Bootloader
      def initialize
        @esp = '/efi'
      end

      # Dracut is used by sys-kernel/gentoo-kernel
      def dependencies
        Install.new('app-shells/dash')
        if not Helpers.efi? and not Helpers.systemd?
          ChrootOutput.new('emerge --update --newuse sys-boot/grub')
        end
      end

      def install
        Helpers.grub? ?
          Config::Grub.new :
          Getch::Chroot.new("bootctl --path #{@esp} install")

        #ChrootOutput.new('emerge --config sys-kernel/gentoo-kernel')
        ChrootOutput.new('emerge --config sys-kernel/gentoo-kernel-bin')
      end
    end
  end
end
