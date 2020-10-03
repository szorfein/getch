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
            exec("euse -p sys-boot/grub -E device-mapper")
            exec("euse -p sys-fs/cryptsetup -E luks1_default")
          end

          def install_deps
            exec("euse -E cryptsetup") if ! Helpers::grep?("#{MOUNTPOINT}/etc/portage/make.conf", /cryptsetup/)
            Getch::Emerge.new('genkernel sys-apps/systemd sys-fs/cryptsetup').pkg!
          end

          def exec(cmd)
            Helpers::run_chroot(cmd, MOUNTPOINT)
          end
        end
      end
    end
  end
end
