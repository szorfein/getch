module Getch
  module Gentoo
    class Sources
      def initialize
        @lsmod = `lsmod`.chomp
        @linux = '/usr/src/linux'
      end

      def build_others
        install_wifi if ismatch?('iwlwifi')
        install_zfs if ismatch?('zfs')
        virtualbox_guest
        qemu_guest
      end

      def build_kspp
        puts "Adding KSPP to the kernel source"
        exec("./kernel.sh -b -a systemd -k #{@linux}")
      end

      def make
        puts "Compiling kernel sources"
        only_make
        cmd = "cd #{@linux} && make modules_install && make install"
        exec_chroot(cmd)
      end

      def only_make
        exec_chroot("cd #{@linux} && make -j$(nproc)")
      end

      def init_config
        exec_chroot("env-update && cd #{@linux} && make localyesconfig")
      end

      private

      def virtualbox_guest
        exec("./kernel.sh -b -a virtualbox-guest -k #{@linux}") if ismatch?('vmwgfx')
        Helpers::emerge("app-emulation/virtualbox-guest-additions", MOUNTPOINT)
      end

      def qemu_guest
        exec("./kernel.sh -a qemu-guest -k #{@linux}") if ismatch?('virtio')
        exec("./kernel.sh -a kvm -k #{@linux}") if ismatch?('kvm')
      end

      def ismatch?(arg)
        @lsmod.match?(/#{arg}/)
      end

      def exec(cmd)
        script = "chroot #{MOUNTPOINT} /bin/bash -c \"
          source /etc/profile
          cd /root/garden-master
          #{cmd}
        \""
        Getch::Command.new(script).run!
      end

      def exec_chroot(cmd)
        script = "chroot #{MOUNTPOINT} /bin/bash -c \"
          source /etc/profile
          #{cmd}
        \""
        Getch::Command.new(script).run!
      end

      def install_wifi
        exec("./kernel.sh -b -a wifi -k #{@linux}")
        Helpers::emerge("net-wireless/iw wpa_supplicant", MOUNTPOINT)
      end

      def install_zfs
        exec("./kernel.sh -b -a zfs -k #{@linux}")
        only_make # a first make is necessary before emerge zfs
        Helpers::emerge("zfs", MOUNTPOINT)
      end
    end
  end
end
