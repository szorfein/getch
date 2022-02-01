# frozen_string_literal: true

module Getch
  module Gentoo
    class Bootloader
      def initialize
        @esp = '/efi'
        x
      end

      protected

      def x
        dependencies
        setup
        initramfs
      end

      private

      # Dracut is used by sys-kernel/gentoo-kernel
      def dependencies
        Install.new('app-shells/dash')
      end

      def setup
        if Helpers.efi? and not OPTIONS[:musl]
          Getch::Chroot.new("bootctl --path #{@esp} install")
        else
          ChrootOutput.new('emerge --update --newuse sys-boot/grub')
          Config::Grub.new
        end
      end

      def initramfs
        ChrootOutput.new('emerge --config sys-kernel/gentoo-kernel')
      end
    end
  end
end
