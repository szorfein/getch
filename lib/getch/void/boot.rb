require 'fileutils'
require_relative '../helpers'

module Getch
  module Void
    class Boot
      include Helpers::Void

      def initialize
        @efi = Helpers::efi?
        @class_fs = Getch::select_fs
        @fs = @class_fs::Void.new
        @user = OPTIONS[:username]
        @fs.create_key if @class_fs::Void.method_defined? :create_key
      end

      def new_user
        puts " => Add a password for root."
        chroot "passwd"
        puts
        return unless @user
        print " => Creating a new user #{@user}..."
        puts "\s[OK]"
        command "useradd -m -G users,wheel,audio,video #{@user}"
        puts " => Add a password for #{@user}."
        chroot "passwd #{@user}"
        puts
      end

      def fstab
        print " => Configuring fstab..."
        @fs.fstab
        puts "\s[OK]"
        @fs.crypttab if @class_fs::Void.method_defined? :crypttab
      end

      def dracut
        print " => Configuring Dracut..."
        @fs.config_dracut
        @fs.kernel_cmdline_dracut
        puts "\s[OK]"
      end

      def grub
        disk = OPTIONS[:boot_disk] ||= OPTIONS[:disk]
        print " => Installing Grub on #{disk}..."
        if @efi
          command_output "xbps-install -y grub-x86_64-efi"
          @fs.config_grub if @class_fs::Void.method_defined? :config_grub
          command_output "grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=\"Void\""
        else
          command_output "xbps-install -y grub"
          @fs.config_grub if @class_fs::Void.method_defined? :config_grub
          command_output "grub-install /dev/#{disk}"
        end
      end

      def initramfs
        puts " => Generating an initramfs..."
        command_output "xbps-reconfigure -fa" # this command also start grub-mkconfig
      end

      def finish
        puts
        puts "[*!*] Install finished [*!*]"
        puts
        @fs.finish
        puts
      end

      private

      def chroot(cmd)
        system("chroot", MOUNTPOINT, "/bin/bash", "-c", cmd)
      end
    end
  end
end
