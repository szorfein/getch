# frozen_string_literal: true

module Getch
  module Gentoo
    class Terraform
      def initialize
        x
      end

      protected

      def x
        Gentoo::Sources.new
        install_pkgs
      end

      def install_pkgs
        @pkgs << 'app-portage/gentoolkit'
        @pkgs << ' app-admin/sudo'
        @pkgs << ' app-editors/vim'
        @pkgs << ' net-firewall/iptables'
        @pkgs << ' net-wireless/iwd'
        @pkgs << ' net-misc/dhcpcd'
        @pkgs << ' sys-firmware/intel-microcode'
        @pkgs << ' sys-fs/dosfstools' if Helpers.efi?
        Install.new(@pkgs)
      end
    end
  end
end
