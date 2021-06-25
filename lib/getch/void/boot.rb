require 'fileutils'
require_relative '../../helpers'

module Getch::Void
  class Boot
    include Helpers::Void

    def initialize
      @efi = Helpers::efi?
      @class_fs = Getch::select_fs
      @fs = @class_fs::Void.new
      @user = Getch::OPTIONS[:username]
    end

    def new_user
      puts " => Add a password for root."
      command_output "passwd"
      puts
      return unless @user
      print " => Creating a new user #{@user}..."
      puts "\s[OK]"
      command "useradd -m -G users,wheel,audio,video #{@user}" 
      puts " => Add a password for #{@user}."
      command "passwd #{@user}" 
      puts
    end

    def fstab
      print " => Configuring fstab..."
      @fs.fstab
      puts "\s[OK]"
    end

    def dracut
      print " => Configuring Dracut..."
      @fs.config_dracut
      @fs.kernel_cmdline_dracut
      puts "\s[OK]"
    end

    def grub
      print " => Installing Grub on #{@fs.boot_disk}..."
      if @efi
        command_output "xbps-install grub-x86_64-efi"
        command_output "grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=\"Void\""
      else
        command_output "xbps-install grub"
        command_output "grub-install /dev/#{@fs.boot_disk}"
      end
      puts "\s[OK]"
    end

    def initramfs
      print " => Generating an initramfs..."
      command_output "xbps-reconfigure -fa" # this command also start grub-mkconfig
      puts "\s[OK]"
    end

    def finish
      puts
      puts "[*!*] Install finished [*!*]"
      puts
      @fs.finish
      puts
    end
  end
end
