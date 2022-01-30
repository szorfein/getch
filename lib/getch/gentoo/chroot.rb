# frozen_string_literal: true

require 'nito'

module Getch
  module Gentoo
    class Chroot
      include NiTo

      def initialize
        @pkgs = []
      end

      def cpuflags
        Getch::Emerge.new('app-portage/cpuid2cpuflags').pkg!
        cpuflags = `chroot #{MOUNTPOINT} /bin/bash -c "source /etc/profile; cpuid2cpuflags"`.chomp
        File.write("#{MOUNTPOINT}/etc/portage/package.use/00cpuflags", "*/* #{cpuflags}")
      end

      def update
        STATES[:gentoo_update] && return

        puts 'Downloading the last ebuilds for Gentoo...'
        mkdir "#{MOUNTPOINT}/var/db/repos/gentoo"
        cmd = 'emaint sync --auto'
        exec_chroot(cmd)
      end

      def world
        STATES[:gentoo_update] && return

        puts 'Update Gentoo world'
        Getch::Emerge.new('emerge --update --deep --changed-use --newuse @world').run!
      end

      def systemd
        puts 'Updating locale, keymap...'
        cmd = 'locale-gen; emerge --config sys-libs/timezone-data'
        exec_chroot(cmd)
      end

      # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base
      def kernel_license
        license = "#{MOUNTPOINT}/etc/portage/package.license"
        mkdir license, 0744
        conf = "#{license}/kernel"
        Helpers.echo conf, 'sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE'
        Helpers.echo_a conf, 'sys-firmware/intel-microcode intel-ucode'
      end

      def install_pkgs
        @pkgs << 'app-portage/gentoolkit'
        @pkgs << 'app-admin/sudo'
        @pkgs << 'app-editors/vim'
        @pkgs << 'net-firewall/iptables'
        @pkgs << 'sys-firmware/intel-microcode' unless OPTIONS[:musl] # bug
        @pkgs << 'sys-fs/dosfstools' if Helpers.efi?
        all_pkgs = @pkgs.join(' ')
        Getch::Emerge.new(all_pkgs).pkg!
      end

      private

      def exec_chroot(cmd)
        Getch::Chroot.new(cmd).run!
      end
    end
  end
end
