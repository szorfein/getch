require 'fstab'
require 'dracut'

module Getch
  module FileSystem
    module Zfs
      module Minimal
        class Config
          def initialize
            @mountpoint = OPTIONS[:mountpoint]
            @zfs = OPTIONS[:zfs_name] ||= 'pool'
            @os = OPTIONS[:os]
            x
          end

          private

          def x
            Fstab::Zfs.new(DEVS, OPTIONS).generate
            Dracut::Zfs.new(DEVS, OPTIONS).generate
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
