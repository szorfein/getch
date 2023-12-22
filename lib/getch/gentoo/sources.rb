# frozen_string_literal: true

require 'cmdline'
require 'nito'

module Getch
  module Gentoo
    # Here we install the kernel linux.
    # We compile source, enable and disable few modules for the new system.
    class Sources
      include NiTo

      def initialize
        @log = Log.new
        @lsmod = `lsmod`.chomp
        x
      end

      protected

      def x
        bask
        gen_cmdline
        grub_mkconfig
        use_flags
        make
      end

      def bask
        @log.info "Kernel hardening...\n"
        # Getch::Bask.new('10_kspp.config').cp
        Getch::Bask.new('11-kspp-gcc.config').cp
        Getch::Bask.new('12-kspp-x86_64.config').cp
        # Getch::Bask.new('20-clipos.config').cp
        Getch::Bask.new('30-grsecurity.config').cp
        # Getch::Bask.new('40-kconfig-hardened.config').cp
        Getch::Bask.new('50-blacklist.config').cp
        Getch::Bask.new('51-blacklist-madaidans.config').cp
      end

      def gen_cmdline
        cmdline = CmdLine::Kernel.new(workdir: "#{MOUNTPOINT}/etc/kernel")
        cmdline.main
      end

      def grub_mkconfig
        return if Helpers.systemd_minimal?

        # https://wiki.gentoo.org/wiki/Project:Distribution_Kernel
        use = Getch::Gentoo::Use.new('sys-kernel/installkernel-gentoo')
        use.add('grub')
      end

      def use_flags
        use = Getch::Gentoo::Use.new('sys-kernel/gentoo-kernel')
        use.add('hardened')
      end

      # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Alternative:_Using_distribution_kernels
      def make
        if Helpers.systemd_minimal?
          Install.new('sys-kernel/installkernel-systemd')
        else
          Install.new('sys-kernel/installkernel-gentoo')
        end

        # Install.new 'sys-kernel/gentoo-kernel'
        Install.new 'sys-kernel/gentoo-kernel-bin'
      end

      def load_modules
        wifi
        flash_mod
      end

      private

      def ismatch?(arg)
        @lsmod.match?(/#{arg}/)
      end

      def wifi
        return unless ismatch?('cfg80211')

        conf = "#{MOUNTPOINT}/etc/modules-load.d/wifi.conf"
        File.delete(conf) if File.exist? conf

        module_load('iwlmvm', conf)
        module_load('ath9k', conf)
        module_load('rt73usb', conf)
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
        return unless ismatch?(name)

        File.write(file, "#{name}\n", mode: 'a')
      end
    end
  end
end
