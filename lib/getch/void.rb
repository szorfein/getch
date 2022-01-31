# frozen_string_literal: true

require_relative 'void/boot'

module Getch
  module Void
    class Main
      def chroot
        chroot = Getch::Void::Chroot.new
        chroot.update
        chroot.fs
        chroot.extras
        chroot.install_pkgs
      end

      def kernel
        Getch::Void::Sources.new
      end

      def boot
        boot = Getch::Void::Boot.new
        boot.new_user
        boot.fstab
        boot.dracut
        boot.grub
        boot.initramfs
        boot.finish
      end
    end
  end
end

require_relative 'void/tarball'
require_relative 'void/pre_config'
require_relative 'void/update'
require_relative 'void/post_config'
require_relative 'void/terraform'
