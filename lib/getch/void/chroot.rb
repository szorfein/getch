# frozen_string_literal: true

module Getch
  module Void
    class Chroot
      include Helpers::Void

      def initialize
        @state = Getch::States.new
        @pkgs = []
      end

      # https://docs.voidlinux.org/installation/guides/chroot.html#install-base-system-rootfs-method-only
      def update
        return if STATES[:gentoo_update]

        command_output '/usr/bin/xbps-install -Suy xbps' # y to force (--yes)
        command_output '/usr/bin/xbps-install -uy'
        command_output '/usr/bin/xbps-install -y base-system'
        #command_output '/usr/bin/xbps-remove base-voidstrap'
        @state.update
      end

      def extras
        @pkgs << 'vim'
        @pkgs << 'iptables'
        @pkgs << 'iwd'
      end

      def fs
        @pkgs << 'lvm2' if OPTIONS[:fs] == 'lvm'
        @pkgs << 'zfs' if OPTIONS[:fs] == 'zfs'
        @pkgs << 'cryptsetup' if OPTIONS[:encrypt]
      end

      def install_pkgs
        all_pkgs = @pkgs.join(' ')
        command_output "/usr/bin/xbps-install -y #{all_pkgs}"
      end
    end
  end
end
