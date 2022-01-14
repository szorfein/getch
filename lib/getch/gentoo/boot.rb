# frozen_string_literal: true

require 'fileutils'

module Getch
  module Gentoo
    class Boot
      def initialize
        @user = Getch::OPTIONS[:username]
      end

      def start
        bootloader
        password
        permission
        the_end
      end

      def bootloader
        # Ensure all packages are build
        Getch::Emerge.new('@world').pkg!
        Helpers.efi? ? bootctl : grub
      end

      # bootctl is alrealy installed with the stage3-amd64-systemd
      def bootctl
        # ref: https://forums.gentoo.org/viewtopic-p-8118822.html
        esp = '/efi'
        puts ' => Updating systemd-boot...'
        Getch::Chroot.new("bootctl --path #{esp} update").run!
      end

      def grub
        puts ' => Updating GRUB...'
        Getch::Chroot.new('grub-mkconfig -o /boot/grub/grub.cfg').run!
      end

      def password
        puts 'Password for root'
        chroot "passwd"
        return unless @user

        puts "Creating user #{@user}"
        Getch::Chroot.new("useradd -m -G users,wheel,audio,video #{@user}").run!
        puts "Password for your user #{@user}"
        chroot "passwd #{@user}"
      end

      private

      def permission
        FileUtils.chmod_R 0755, "#{MOUNTPOINT}/etc/portage"
        if @user
          Getch::Chroot.new("chown -R #{@user}:#{@user} /home/#{@user}").run!
        end
      end

      def the_end
        puts
        puts 'getch has finish, before reboot, you can:'
        puts "  +  Chroot on your system with: chroot #{MOUNTPOINT} /bin/bash"
        puts '  +  Install more packages like networkmanager or emacs'
        puts
        puts '  +  Add more modules for your kernel (graphic, wifi card) and recompile it with:'
        puts '  genkernel --kernel-config=/usr/src/linux/.config all  '
        puts
        puts 'Reboot the system when you have done !'
      end

      def chroot(cmd)
        system('chroot', MOUNTPOINT, '/bin/bash', '-c', cmd)
      end
    end
  end
end
