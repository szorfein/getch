# frozen_string_literal: true

require 'fstab'
require 'dracut'
require 'cryptsetup'

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Config
          def initialize
            x
          end

          private

          def x
            Fstab::Zfs.new(DEVS, OPTIONS).generate
            Dracut::Zfs.new(DEVS, OPTIONS).generate
            CryptSetup.new(DEVS, OPTIONS).swap_conf
            grub_broken_root
          end

          # https://wiki.archlinux.org/title/Install_Arch_Linux_on_ZFS#Using_GRUB_for_EFI/BIOS
          def grub_broken_root
            return unless Helpers.grub?

            file = "#{@mountpoint}/etc/default/grub"
            content = "GRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX"
            content << " root=ZFS=r#{@zfs}/ROOT/#{@os}\""
            NiTo.echo_a file, content
          end
        end
      end
    end
  end
end
