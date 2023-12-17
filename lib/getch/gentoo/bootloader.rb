# frozen_string_literal: true

module Getch
  module Gentoo
    # install grub or bootctl
    class Bootloader
      def initialize
        @esp = '/efi'
        @boot = DEVS[:boot] ||= nil
        @encrypt = OPTIONS[:encrypt] ||= false
      end

      # Dracut is used by sys-kernel/gentoo-kernel
      def dependencies
        Install.new('app-shells/dash')
        if Helpers.systemd? && Helpers.efi? && !@encrypt
          Log.new.info "Systemd-boot alrealy installed...\n"
        else
          ChrootOutput.new('emerge --update --newuse sys-boot/grub')
        end
      end

      def install
        if Helpers.grub?
          Config::Grub.new
        else
          bootctl
        end

        # ChrootOutput.new('emerge --config sys-kernel/gentoo-kernel')
        ChrootOutput.new('emerge --config sys-kernel/gentoo-kernel-bin')
      end

      def bootctl
        if @boot
          with_boot
        else
          Chroot.new("bootctl --esp-path=#{@esp} install")
        end
      end

      # We need to umount the encrypted /boot first
      # https://github.com/systemd/systemd/issues/16151
      def with_boot
        boot = @encrypt ? '/dev/mapper/boot-luks' : "/dev/#{DEVS[:boot]}"
        NiTo.umount "#{OPTIONS[:mountpoint]}/boot"
        Chroot.new("bootctl --esp-path=#{@esp} install")
        NiTo.mount boot, "#{OPTIONS[:mountpoint]}/boot"
      end
    end
  end
end
