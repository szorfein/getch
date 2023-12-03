# frozen_string_literal: true

module Getch
  module Config
    # Configure iwd if wifi is detected
    class Iwd
      include NiTo

      def initialize
        @options = "[General]\nUseDefaultInterface=true\n"
        x
      end

      protected

      def x
        runit
        systemd
        openrc
      end

      private

      # https://docs.voidlinux.org/config/network/iwd.html
      def runit
        Helpers.runit? || return

        iwd_conf
        service = '/etc/runit/runsvdir/default/'
        Chroot.new("ln -fs /etc/sv/dbus #{service}")
        Chroot.new("ln -fs /etc/sv/iwd #{service}")
      end

      def systemd
        Helpers.systemd? || return

        iwd_conf
        Chroot.new('systemctl enable iwd')
      end

      def openrc
        Helpers.openrc? || return

        iwd_conf
        Chroot.new('rc-update add iwd default')
      end

      # https://docs.voidlinux.org/config/network/iwd.html#troubleshooting
      def iwd_conf
        conf = "#{OPTIONS[:mountpoint]}/etc/iwd/main.conf"
        content = @options.dup
        content << "[Network]\n"
        content << if Helpers.systemd?
                     "NameResolvingService=systemd\n"
                   else
                     "NameResolvingService=resolvconf\n"
                   end
        mkdir "#{OPTIONS[:mountpoint]}/etc/iwd"
        echo conf, "#{content}\n"
      end
    end
  end
end
