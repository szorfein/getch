# frozen_string_literal: true

module Getch
  module Gentoo
    class Bootloader
      def initialize
        @esp = '/efi'
        @boot = DEVS[:boot] ||= nil
        @encrypt = OPTIONS[:encrypt] ||= false
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
          bootctl

        #ChrootOutput.new('emerge --config sys-kernel/gentoo-kernel')
        ChrootOutput.new('emerge --config sys-kernel/gentoo-kernel-bin')
      end

      def bootctl
        @boot ?
          with_boot :
          Chroot.new("bootctl --path #{@esp} install")
      end

      # We need to umount the encrypted /boot first
      # https://github.com/systemd/systemd/issues/16151
      def with_boot
        boot = @encrypt ? '/dev/mapper/boot-luks' : "/dev/#{DEVS[:boot]}"
        NiTo.umount "#{OPTIONS[:mountpoint]}/boot"
        Chroot.new("bootctl --path #{@esp} install")
        NiTo.mount boot, "#{OPTIONS[:mountpoint]}/boot"
      end
    end
  end
end
