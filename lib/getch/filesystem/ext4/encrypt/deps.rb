module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Deps
          def initialize
            if Helpers::efi?
              install_efi
            else
              install_bios
            end
            install_deps
          end

          def make
            genkernel
            Getch::Make.new("genkernel --kernel-config=/usr/src/linux/.config all").run!
          end

          private
          def install_efi
          end

          def genkernel
            grub = Helpers::efi? ? 'BOOTLOADER="no"' : 'BOOTLOADER="grub2"'
            datas = [
              '',
              grub,
              'INSTALL="yes"',
              'MENUCONFIG="no"',
              'CLEAN="yes"',
              "KEYMAP=\"#{DEFAULT_OPTIONS[:keyboard]}\"",
              'SAVE_CONFIG="yes"',
              'MOUNTBOOT="yes"',
              'MRPROPER="no"',
              'LUKS="yes"',
            ]
            file = "#{MOUNTPOINT}/etc/genkernel.conf"
            File.write(file, datas.join("\n"), mode: 'a')
          end

          def install_bios
            exec("euse -p sys-boot/grub -E device-mapper")
          end

          def install_deps
            exec("euse -E cryptsetup")
            Getch::Emerge.new('genkernel sys-apps/systemd sys-fs/cryptsetup').pkg!
          end

          def exec(cmd)
            Getch::Command.new(cmd).run!
          end
        end
      end
    end
  end
end
