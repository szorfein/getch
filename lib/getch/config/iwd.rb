module Getch
  module Config
    class Iwd
      include NiTo

      def initialize
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
        content = "[General]\n"
        content << "UseDefaultInterface=true\n"
        content << "[Network]\n"
        Helpers.systemd? ?
          content << "NameResolvingService=systemd\n" :
          content << "NameResolvingService=resolvconf\n"
        content << "[Scan]\n"
        content << "DisablePeriodicScan=true\n"
        mkdir "#{OPTIONS[:mountpoint]}/etc/iwd"
        echo conf, "#{content}\n"
      end
    end
  end
end
