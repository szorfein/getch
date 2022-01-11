require_relative '../helpers'

module Getch
  module Void
    class Chroot
      include Helpers::Void

      def initialize
        @state = Getch::States.new()
        @pkgs = []
        mount
      end

      # https://docs.voidlinux.org/installation/guides/chroot.html#install-base-system-rootfs-method-only
      def update
        return if STATES[:gentoo_update]
        command_output "/usr/bin/xbps-install -Suy xbps" # y to force (--yes)
        command_output "/usr/bin/xbps-install -uy"
        command_output "/usr/bin/xbps-install -y base-system"
        #command_output "/usr/bin/xbps-remove base-voidstrap"
        @state.update
      end

      def extras
        @pkgs << "vim"
        @pkgs << "iptables"
        @pkgs << "iwd"
      end

      def fs
        @pkgs << "lvm2" if OPTIONS[:fs] == 'lvm'
        @pkgs << "zfs" if OPTIONS[:fs] == 'zfs'
        @pkgs << "cryptsetup" if OPTIONS[:encrypt]
      end

      def install_pkgs
        all_pkgs = @pkgs.join(" ")
        command_output "/usr/bin/xbps-install -y #{all_pkgs}"
      end

      private

      def mount
        puts "Populate /proc, /sys and /dev."
        Helpers.exec_or_die("mount --types proc /proc \"#{MOUNTPOINT}/proc\"")
        Helpers.exec_or_die("mount --rbind /sys \"#{MOUNTPOINT}/sys\"")
        Helpers.exec_or_die("mount --make-rslave \"#{MOUNTPOINT}/sys\"")
        Helpers.exec_or_die("mount --rbind /dev \"#{MOUNTPOINT}/dev\"")
        Helpers.exec_or_die("mount --make-rslave \"#{MOUNTPOINT}/dev\"")
        # Maybe add /dev/shm like describe here:
        # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base
      end
    end
  end
end
