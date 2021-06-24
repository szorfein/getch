require_relative 'void/stage'
require_relative 'void/config'
require_relative 'void/chroot'
require_relative 'void/sources'
require_relative 'void/boot'
require_relative 'void/use'
require_relative 'void/use_flag'

module Getch
  module Void
    class Main
      def initialize
        @state = Getch::States.new()
      end

      def static_xbps
        return if STATES[:gentoo_base]
        xbps = Getch::Void::Xbps.new
        xbps.search_archive
        xbps.download
        xbps.checksum
        @state.stage3
      end

      def config
        return if STATES[:gentoo_config]
        config = Getch::Void::Config.new
        config.network
        config.hostname
        @state.config
      end

      def chroot
        chroot = Getch::Void::Chroot.new
        chroot.update
        chroot.cpuflags
        chroot.systemd

        chroot.world
        return if STATES[:gentoo_kernel]
        chroot.kernel
        chroot.kernel_deps
        chroot.install_pkgs
        chroot.kernel_link
      end

      def kernel
        return if STATES[:gentoo_kernel]
        source = Getch::Void::Sources.new
        source.build_kspp
        source.build_others
        source.firewall
        source.make
        @state.kernel
      end

      def boot
        boot = Getch::Void::Boot.new
        boot.start
      end
    end
  end
end
