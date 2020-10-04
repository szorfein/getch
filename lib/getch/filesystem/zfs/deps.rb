module Getch
  module FileSystem
    module Zfs
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
            'ZFS="yes"',
          ]
          file = "#{MOUNTPOINT}/etc/genkernel.conf"
          File.write(file, datas.join("\n"), mode: 'a')
        end

        def install_efi
        end

        def install_bios
        end

        def install_deps
          exec("euse -E libzfs")
          Getch::Garden.new('-a zfs').run!
          Getch::Make.new("make -j$(nproc)")
          Getch::Emerge.new('genkernel sys-fs/zfs').pkg!
        end

        def exec(cmd)
          Helpers::run_chroot(cmd, MOUNTPOINT)
        end
      end
    end
  end
end
