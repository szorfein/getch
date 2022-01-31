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
        #update
      end

      private

      def sync
        @log.info 'Synchronize index...'
        Command.Chroot.new('/usr/bin/xbps-install', '-Suy', 'xbps').run!
        @log.result 'Ok'
      end

      def update
        command_output '/usr/bin/xbps-install -uy'
        command_output '/usr/bin/xbps-install -y base-system'
        command_output '/usr/bin/xbps-remove base-voidstrap'
      end
    end
  end
end
