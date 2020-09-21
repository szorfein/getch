module Getch
  module Gentoo
    class Chroot
      def initialize
        @state = Getch::States.new()
        mount
      end

      def update
        return if STATES[:gentoo_update]
        puts "Downloading the last ebuilds for Gentoo..."
        cmd = "emerge-webrsync"
        exec_chroot(cmd)
      end

      def world
        return if STATES[:gentoo_update]
        puts "Update Gentoo"
        cmd = "emerge --update --deep --newuse @world"
        exec_chroot(cmd)
        @state.update
      end

      def systemd
        puts "Updating locale, keymap..."
        cmd = "locale-gen; emerge --config sys-libs/timezone-data"
        exec_chroot(cmd)
      end

      def kernel
        return if Dir.exist? "#{MOUNTPOINT}/usr/src/linux"
        puts "Installing kernel gentoo-sources..."
        license = "#{MOUNTPOINT}/etc/portage/package.license"
        File.write(license, "sys-kernel/linux-firmware linux-fw-redistributable no-source-code\n")
        Helpers::emerge("sys-kernel/gentoo-sources linux-firmware dev-util/dwarves", MOUNTPOINT)
      end

      def kernel_deps
        puts "Installing Garden..."
        get_garden
        garden_dep
      end

      def install_tools
        Helpers::emerge("sudo vim", MOUNTPOINT)
      end

      private

      def get_garden
        return if Dir.exist? "#{MOUNTPOINT}/root/garden-master"
        url = 'https://github.com/szorfein/garden/archive/master.tar.gz'
        file = 'garden-master.tar.gz'

        Dir.chdir("#{MOUNTPOINT}/root")
        Helpers::get_file_online(url, file)
        Getch::Command.new("tar xzf #{file}").run! if ! Dir.exist? 'garden-master'
      end

      def garden_dep
        Helpers::emerge("gentoolkit", MOUNTPOINT)
        cmd = "euse -p sys-apps/kmod -E lzma"
        Helpers::emerge("kmod", MOUNTPOINT)
        exec_chroot(cmd)
      end

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

      def exec_chroot(cmd)
        script = "chroot #{MOUNTPOINT} /bin/bash -c \"
          source /etc/profile
          #{cmd}
        \""
        Getch::Command.new(script).run!
      end
    end
  end
end
