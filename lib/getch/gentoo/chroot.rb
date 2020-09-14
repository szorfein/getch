module Getch
  module Gentoo
    class Chroot
      def initialize
        mount
      end

      def update
        puts "Downloading the last ebuilds for Gentoo..."
        cmd = "chroot #{MOUNTPOINT} /bin/bash -c \"
          source /etc/profile
          emerge-webrsync
        \""
        Helpers::exec_or_die(cmd)
      end

      private
      def mount
        puts "Populate /proc, /sys and /dev."
        Helpers::exec_or_die("mount --types proc /proc \"#{MOUNTPOINT}/proc\"")
        Helpers::exec_or_die("mount --rbind /sys \"#{MOUNTPOINT}/sys\"")
        Helpers::exec_or_die("mount --make-rslave \"#{MOUNTPOINT}/sys\"")
        Helpers::exec_or_die("mount --rbind /dev \"#{MOUNTPOINT}/dev\"")
        Helpers::exec_or_die("mount --make-rslave \"#{MOUNTPOINT}/dev\"")
        # Maybe add /dev/shm like describe here:
        # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base
      end
    end
  end
end
