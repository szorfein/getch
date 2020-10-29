module Getch
  module FileSystem
    module Lvm
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
          options_make
          Getch::Make.new("genkernel --kernel-config=/usr/src/linux/.config all").run!
        end

        private
        def options_make
          grub = Helpers::efi? ? 'BOOTLOADER="no"' : 'BOOTLOADER="grub2"'
          datas = [
            '',
            grub,
            'INSTALL="yes"',
            'MENUCONFIG="no"',
            'CLEAN="yes"',
            'SAVE_CONFIG="yes"',
            'MOUNTBOOT="yes"',
            'MRPROPER="no"',
            'LVM="yes"',
          ]
          file = "#{MOUNTPOINT}/etc/genkernel.conf"
          File.write(file, datas.join("\n"), mode: 'a')
        end

        def install_efi
        end

        def install_bios
          exec("euse -p sys-boot/grub -E device-mapper")
        end

        def install_deps
          make_conf = "#{MOUNTPOINT}/etc/portage/make.conf"
          exec("euse -E lvm") if ! Helpers::grep?(make_conf, /lvm/)
          Getch::Emerge.new('genkernel lvm2').pkg!
          Getch::Bask.new('-a lvm').run!
          exec("systemctl enable lvm2-monitor")
        end

        def exec(cmd)
          Getch::Chroot.new(cmd).run!
        end
      end
    end
  end
end
