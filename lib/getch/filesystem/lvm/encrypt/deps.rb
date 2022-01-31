# frozen_string_literal: true

module Getch
  module FileSystem
    module Lvm
      module Encrypt
        class Deps
          def make
            install_deps
            options_make
            Getch::Make.new('genkernel --kernel-config=/usr/src/linux/.config all')
          end

          private

          def options_make
            grub = Helpers.efi? ? 'BOOTLOADER="no"' : 'BOOTLOADER="grub2"'
            datas = [
              '',
              grub,
              'INSTALL="yes"',
              'MENUCONFIG="no"',
              'CLEAN="yes"',
              'KEYMAP="yes"',
              'SAVE_CONFIG="yes"',
              'MOUNTBOOT="yes"',
              'MRPROPER="no"',
              'LVM="yes"',
              'LUKS="yes"',
            ]
            file = "#{MOUNTPOINT}/etc/genkernel.conf"
            File.write(file, datas.join("\n"), mode: 'a')
          end

          def install_deps
            # lvm2, cryptsetup alrealy installed
            Getch::Bask.new('-a lvm')
            exec('systemctl enable lvm2-monitor')
          end

          def exec(cmd)
            Getch::Chroot.new(cmd)
          end
        end
      end
    end
  end
end
