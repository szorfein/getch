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
        cmd = "emerge sys-kernel/gentoo-sources sys-kernel/linux-firmware"
        license = "#{MOUNTPOINT}/etc/portage/package.license"
        File.write(license, "sys-kernel/linux-firmware linux-fw-redistributable no-source-code\n")
        exec_chroot(cmd)
      end

      def kernel_deps
        get_garden
        garden_dep
        garden_build
        @state.kernel
      end

      private

      def get_garden
        return if Dir.exist? "#{MOUNTPOINT}/root/garden-master"
        puts "Downloading garden..."
        url = 'https://github.com/szorfein/garden/archive/master.tar.gz'
        file = 'garden-master.tar.gz'

        Dir.chdir("#{MOUNTPOINT}/root")
        Helpers::get_file_online(url, file)
        Helpers::exec_or_die("tar xzf #{file}") if ! Dir.exist? 'garden-master'
      end

      def garden_dep
        puts "Install dependencies for Garden"
        cmd = "emerge gentoolkit && euse -p sys-apps/kmod -E lzma && emerge kmod"
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
        Helpers::exec_or_die(script)
      end
    end
  end
end