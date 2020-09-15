module Getch
  module Gentoo
    class Sources
      def initialze
        @lsmod = `lsmod`.chomp
        @linux = '/usr/src/linux'
      end

      def build_others
        exec("./kernel.sh -b -a zfs -k #{@linux}") if ismatch?('zfs')
        exec("./kernel.sh -b -a wifi -k #{@linux}") if ismatch?('iwlwifi')
        exec("./kernel.sh -b -a virtualbox-guest -k #{@linux}") if ismatch?('vmwgfx')
      end

      def build_kspp
        puts "Adding KSPP to the kernel source"
        exec("./kernel.sh -b -a 'systemd' -k #{@linux}")
      end

      def make
        puts "Compiling kernel sources"
        cmd = 'cd /usr/src/linux; make -j$(nproc); make modules_install; make install'
        exec_chroot(cmd)
      end
      private

      def ismatch?(arg)
        @lsmod.match?(/#{arg}/)
      end

      def exec(cmd)
        script = "chroot #{MOUNTPOINT} /bin/bash -c \"
          source /etc/profile
          cd /root/garden-master
          #{cmd}
        \""
        Helpers::exec_or_die(script)
      end

      def exec_chroot(cmd)
        script = "chroot #{MOUNTPOINT} /bin/bash -c \"
          source /etc/profile
          #{cmd}
        \""
        Helpers::exec_or_die(script)
      end
    end
  end
end
