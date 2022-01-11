module Getch
  module Gentoo
    class Sources
      def initialize
        @lsmod = `lsmod`.chomp
        @class_fs = Getch::select_fs
        @filesystem = @class_fs::Deps.new
      end

      def build_others
        cryptsetup
        virtualbox_guest
        qemu_guest
        install_wifi
        install_audio
        flash_mod
      end

      def build_kspp
        puts "Adding KSPP to the kernel source"
        bask("-b -a systemd")
      end

      def make
        if Getch::OPTIONS[:fs] == 'lvm' ||
            Getch::OPTIONS[:fs] == 'zfs' ||
            Getch::OPTIONS[:encrypt]
          @filesystem.make
        else
          make_kernel
        end
      end

      def firewall
        bask("-a iptables")
        Getch::Emerge.new("net-firewall/iptables").pkg!
      end

      private

      def make_kernel
        puts "Compiling kernel sources"
        cmd = "make -j$(nproc) && make modules_install && make install"
        Getch::Make.new(cmd).run!
        is_kernel = Dir.glob("#{MOUNTPOINT}/boot/vmlinuz-*")
        raise "No kernel installed, compiling source fail..." if is_kernel == []
      end

      def cryptsetup
        return unless Getch::OPTIONS[:encrypt]
        make_conf = "#{MOUNTPOINT}/etc/portage/make.conf"

        puts "Adding support for cryptsetup."
        bask("-a cryptsetup")
        Getch::Chroot.new("euse -E cryptsetup").run! unless Helpers.grep?(make_conf, /cryptsetup/)
        Getch::Emerge.new("sys-fs/cryptsetup").pkg!
      end

      def virtualbox_guest
        systemd=`systemd-detect-virt`.chomp
        return if ! ismatch?('vmwgfx') || systemd.match(/none/)
        bask("-a virtualbox-guest")
        Getch::Emerge.new("app-emulation/virtualbox-guest-additions").pkg!
      end

      def qemu_guest
        bask("-a kvm-host") if ismatch?('kvm')
        bask("-a kvm-guest") if ismatch?('virtio')
      end

      def ismatch?(arg)
        @lsmod.match?(/#{arg}/)
      end

      def bask(cmd)
        Getch::Bask.new(cmd).run!
      end

      def install_wifi
        return if ! ismatch?('cfg80211')
        bask("-a wifi")
        wifi_drivers
        Getch::Emerge.new("net-wireless/iw wpa_supplicant net-wireless/iwd").pkg!
      end

      def install_audio
        return if ! ismatch?('snd_pcm')
        bask("-a sound")
      end

      def wifi_drivers
        conf = "#{MOUNTPOINT}/etc/modules-load.d/wifi.conf"
        File.delete(conf) if File.exist? conf

        if ismatch?('ath9k')
          bask("-a ath9k-driver")
        end

        module_load("iwlmvm", conf)
        module_load("ath9k", conf)
      end

      def flash_mod
        conf = "#{MOUNTPOINT}/etc/modules-load.d/usb.conf"
        File.delete(conf) if File.exist? conf

        module_load("ehci_pci", conf)
        module_load("rtsx_pci_sdmmc", conf)
        module_load("sdhci_pci", conf)
        module_load("uas", conf)
        module_load("uhci_hcd", conf)
        module_load("xhci_pci", conf)
      end

      def module_load(name, file)
        return unless name
        return unless ismatch?(name)
        File.write(file, "#{name}\n", mode: 'a')
      end
    end
  end
end
