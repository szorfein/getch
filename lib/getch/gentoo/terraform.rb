# frozen_string_literal: true

require 'nito'

module Getch
  module Gentoo
    class Terraform
      include NiTo

      def initialize
        @pkgs = []
        x
      end

      protected

      def x
        Gentoo::Sources.new
      end

      def install_pkgs
        @pkgs << 'app-portage/gentoolkit'
        @pkgs << ' app-admin/sudo'
        @pkgs << ' app-editors/vim'
        @pkgs << ' net-firewall/iptables'
        @pkgs << ' sys-firmware/intel-microcode' unless OPTIONS[:musl] # bug
        @pkgs << ' sys-fs/dosfstools' if Helpers.efi?
        Install.new(@pkgs)
      end

      private

      def exec_chroot(cmd)
        Getch::Chroot.new(cmd)
      end
    end
  end
end
