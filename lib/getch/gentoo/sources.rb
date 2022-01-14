# frozen_string_literal: true

module Getch
  module Gentoo
    class Sources
      def initialize
        @lsmod = `lsmod`.chomp
        @class_fs = Getch::select_fs
        @filesystem = @class_fs::Deps.new
      end

      def configs
      end

      def load_modules
        install_wifi
        flash_mod
      end

      def bask
        puts ' ==> Hardening kernel...'
        Getch::Bask.new('10_kspp.config').cp
        Getch::Bask.new('11-kspp-gcc.config').cp
        Getch::Bask.new('12-kspp-x86_64.config').cp
        Getch::Bask.new('20-blacklist.config').cp
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

      private

      def make_kernel
        puts 'Compiling kernel sources'
        Getch::Emerge.new('sys-kernel/gentoo-kernel').pkg!
        is_kernel = Dir.glob("#{MOUNTPOINT}/boot/vmlinuz-*")
        raise 'No kernel installed, compiling source fail...' if is_kernel == []
      end

      def ismatch?(arg)
        @lsmod.match?(/#{arg}/)
      end

      def install_wifi
        return unless ismatch?('cfg80211')

        wifi_drivers
        Getch::Emerge.new('net-wireless/iwd').pkg!
      end

      def wifi_drivers
        conf = "#{MOUNTPOINT}/etc/modules-load.d/wifi.conf"
        File.delete(conf) if File.exist? conf

        module_load('iwlmvm', conf)
        module_load('ath9k', conf)
      end

      def flash_mod
        conf = "#{MOUNTPOINT}/etc/modules-load.d/usb.conf"
        File.delete(conf) if File.exist? conf

        module_load('ehci_pci', conf)
        module_load('rtsx_pci_sdmmc', conf)
        module_load('sdhci_pci', conf)
        module_load('uas', conf)
        module_load('uhci_hcd', conf)
        module_load('xhci_pci', conf)
      end

      def module_load(name, file)
        return unless name
        return unless ismatch?(name)

        File.write(file, "#{name}\n", mode: 'a')
      end
    end
  end
end
