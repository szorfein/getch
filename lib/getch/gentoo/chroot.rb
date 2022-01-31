# frozen_string_literal: true

require 'nito'

module Getch
  module Gentoo
    class Chroot
      include NiTo

      def initialize
        @pkgs = []
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
