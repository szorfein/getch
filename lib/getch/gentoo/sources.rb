module Getch
  module Gentoo
    class Sources
      def initialize
        @lsmod = `lsmod`.chomp
        @filesystem = OPTIONS_FS[DEFAULT_OPTIONS[:fs]]::Deps.new()
      end

      def build_others
        install_wifi if ismatch?('iwlwifi')
        install_zfs if ismatch?('zfs')
        virtualbox_guest
        qemu_guest
      end

      def build_kspp
        puts "Adding KSPP to the kernel source"
        garden("-b -a systemd")
      end

      def make
        if DEFAULT_OPTIONS[:fs] == 'lvm'
          @filesystem.make
        else
          just_make
        end
      end

      def init_config
        Getch::Make.new("make localyesconfig").run!
      end

      private

      def only_make
        Getch::Make.new("make -j$(nproc)").run!
      end

      def just_make
        puts "Compiling kernel sources"
        cmd = "make -j$(nproc) && make modules_install && make install"
        Getch::Make.new(cmd).run!
        is_kernel = Dir.glob("#{MOUNTPOINT}/boot/vmlinuz-*")
        raise "No kernel installed, compiling source fail..." if is_kernel == []
      end

      def virtualbox_guest
        garden("-a virtualbox-guest") if ismatch?('vmwgfx')
        Getch::Emerge.new("app-emulation/virtualbox-guest-additions").pkg!
      end

      def qemu_guest
        garden("-a kvm-guest") if ismatch?('virtio')
        garden("-a kvm") if ismatch?('kvm')
      end

      def ismatch?(arg)
        @lsmod.match?(/#{arg}/)
      end

      def garden(cmd)
        Getch::Garden.new(cmd).run!
      end

      def install_wifi
        garden("-a wifi")
        Getch::Emerge.new("net-wireless/iw wpa_supplicant").pkg!
      end

      def install_zfs
        garden("-a zfs")
        only_make # a first 'make' is necessary before emerge zfs
        Getch::Emerge.new("sys-fs/zfs").pkg!
      end
    end
  end
end
