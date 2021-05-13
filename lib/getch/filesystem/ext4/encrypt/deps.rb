module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Deps
          def make
            install_bios unless Helpers::efi?
            install_deps
            genkernel
            Getch::Make.new("genkernel --kernel-config=/usr/src/linux/.config all").run!
          end

          private

          def genkernel
            grub = Helpers::efi? ? 'BOOTLOADER="no"' : 'BOOTLOADER="grub2"'
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
              'LUKS="yes"',
            ]
            file = "#{MOUNTPOINT}/etc/genkernel.conf"
            File.write(file, datas.join("\n"), mode: 'a')
          end

          def install_bios
            exec("euse -p sys-boot/grub -D grub_platforms_efi-64")
            exec("euse -p sys-boot/grub -E device-mapper")
          end

          def install_deps
            Getch::Emerge.new('genkernel sys-apps/systemd').pkg!
          end

          def exec(cmd)
            Getch::Chroot.new(cmd).run!
          end
        end
      end
    end
  end
end
