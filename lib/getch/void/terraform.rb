# frozen_string_literal: true

module Getch
  module Void
    # install dependencies packages
    class Terraform
      def initialize
        @deps = 'sudo'
        x
      end

      protected

      def x
        install_pkgs
      end

      def install_pkgs
        @pkgs = @deps.dup
        @pkgs << ' vim'
        @pkgs << ' iptables'
        @pkgs << ' runit-iptables'
        @pkgs << ' iwd'
        @pkgs << ' dhcpcd'
        @pkgs << ' lvm2' if OPTIONS[:lvm]
        @pkgs << ' zfs' if OPTIONS[:fs] == 'zfs'
        @pkgs << ' cryptsetup' if OPTIONS[:encrypt]
        Install.new(@pkgs)
      end
    end
  end
end
