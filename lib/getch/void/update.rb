# frozen_string_literal: true

module Getch
  module Void
    class Update
      def initialize
        @log = Log.new
        x
      end

      protected

      # https://docs.voidlinux.org/installation/guides/chroot.html#install-base-system-rootfs-method-only
      def x
        sync
        update
      end

      private

      def sync
        @log.info "Synchronize index...\n"
        ChrootOutput.new '/usr/bin/xbps-install', '-Suy', 'xbps'
      end

      def update
        ChrootOutput.new '/usr/bin/xbps-install -uy'
        ChrootOutput.new '/usr/bin/xbps-install -y base-system'
        ChrootOutput.new '/usr/bin/xbps-remove -y base-voidstrap'
      end
    end
  end
end
