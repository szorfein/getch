# frozen_string_literal: true

module Getch
  module Gentoo
    class Chroot
      def initialize
        @state = Getch::States.new()
        @pkgs = []
        mount
      end

      def cpuflags
        Getch::Emerge.new('app-portage/cpuid2cpuflags').pkg!
        cpuflags = `chroot #{MOUNTPOINT} /bin/bash -c "source /etc/profile; cpuid2cpuflags"`.chomp
        File.write("#{MOUNTPOINT}/etc/portage/package.use/00cpuflags", "*/* #{cpuflags}")
      end

      def update
        return if STATES[:gentoo_update]

        puts 'Downloading the last ebuilds for Gentoo...'
        Helpers.create_dir("#{MOUNTPOINT}/var/db/repos/gentoo")
        cmd = 'emaint sync --auto'
        exec_chroot(cmd)
      end

      def world
        return if STATES[:gentoo_update]

        puts 'Update Gentoo world'
        Getch::Emerge.new('emerge --update --deep --changed-use --newuse @world').run!
        @state.update
      end

      def systemd
        puts 'Updating locale, keymap...'
        cmd = 'locale-gen; emerge --config sys-libs/timezone-data'
        exec_chroot(cmd)
      end

      def kernel
        return if Dir.exist? "#{MOUNTPOINT}/usr/src/linux"

        license = "#{MOUNTPOINT}/etc/portage/package.license"
        File.write(license, "sys-kernel/linux-firmware linux-fw-redistributable no-source-code\n")
        @pkgs << 'sys-kernel/gentoo-sources'
      end

      def kernel_deps
        @pkgs << 'sys-apps/kmod'
      end

      def install_pkgs
        @pkgs << 'app-portage/gentoolkit'
        @pkgs << 'app-admin/sudo'
        @pkgs << 'app-editors/vim'
        @pkgs << 'sys-kernel/linux-firmware'
        all_pkgs = @pkgs.join(" ")
        puts "Installing #{all_pkgs}..."
        Getch::Emerge.new(all_pkgs).pkg!
      end

      # create a symbolic link for /usr/src/linux
      def kernel_link
        cmd = 'eselect kernel set 1'
        exec_chroot(cmd)
      end

      private

      def mount
        puts 'Populate /proc, /sys and /dev.'
        Helpers.exec_or_die("mount --types proc /proc \"#{MOUNTPOINT}/proc\"")
        Helpers.exec_or_die("mount --rbind /sys \"#{MOUNTPOINT}/sys\"")
        Helpers.exec_or_die("mount --make-rslave \"#{MOUNTPOINT}/sys\"")
        Helpers.exec_or_die("mount --rbind /dev \"#{MOUNTPOINT}/dev\"")
        Helpers.exec_or_die("mount --make-rslave \"#{MOUNTPOINT}/dev\"")
        # Maybe add /dev/shm like describe here:
        # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base
      end

      def exec_chroot(cmd)
        Getch::Chroot.new(cmd).run!
      end
    end
  end
end
