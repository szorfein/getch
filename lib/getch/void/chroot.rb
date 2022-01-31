# frozen_string_literal: true

module Getch
  module Void
    class Chroot
      include Helpers::Void

      def initialize
        @pkgs = []
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
