# frozen_string_literal: true

module Getch
  module Void
    class Terraform
      include Helpers::Void

      def initialize
        @pkgs = []
        x
      end

      protected

      def x
      end

      def extras
        @pkgs << 'vim'
        @pkgs << ' iptables'
        @pkgs << ' iwd'
      end

      def fs
        @pkgs << ' lvm2' if OPTIONS[:fs] == 'lvm'
        @pkgs << ' zfs' if OPTIONS[:fs] == 'zfs'
        @pkgs << ' cryptsetup' if OPTIONS[:encrypt]
      end

      def install_pkgs
        Install @pkgs
      end
    end
  end
end
