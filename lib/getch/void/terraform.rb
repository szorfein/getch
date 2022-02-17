module Getch
  module Void
    class Terraform
      def initialize
        x
      end

      protected

      def x
        install_pkgs
      end

      def install_pkgs
        @pkgs = 'sudo'
        @pkgs << ' vim'
        @pkgs << ' iptables'
        @pkgs << ' runit-iptables'
        @pkgs << ' iwd'
        @pkgs << ' dhcpcd'
        @pkgs << ' lvm2' if OPTIONS[:fs] == 'lvm'
        @pkgs << ' zfs' if OPTIONS[:fs] == 'zfs'
        @pkgs << ' cryptsetup' if OPTIONS[:encrypt]
        Install.new(@pkgs)
      end
    end
  end
end
