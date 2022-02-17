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
        emerge_deep
      end

      def install_pkgs
        @pkgs = 'app-portage/gentoolkit'
        @pkgs << ' app-admin/sudo'
        @pkgs << ' app-editors/vim'
        @pkgs << ' net-firewall/iptables'
        @pkgs << ' net-wireless/iwd'
        @pkgs << ' net-misc/dhcpcd' unless Helpers.systemd?
        @pkgs << ' sys-kernel/linux-firmware'
        @pkgs << ' sys-firmware/intel-microcode'
        @pkgs << ' sys-fs/dosfstools' if Helpers.efi?
        Install.new(@pkgs)
      end

      def emerge_deep
        ChrootOutput.new('emerge --deep --newuse @world')
      end
    end
  end
end
