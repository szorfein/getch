module Getch
  module FileSystem
    module Lvm
      class Deps
        def make
          install_bios unless Helpers.efi?
          install_deps
          options_make
          Getch::Make.new('genkernel --kernel-config=/usr/src/linux/.config all').run!
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
            'SAVE_CONFIG="yes"',
            'MOUNTBOOT="yes"',
            'MRPROPER="no"',
            'LVM="yes"',
          ]
          file = "#{MOUNTPOINT}/etc/genkernel.conf"
          File.write(file, datas.join("\n"), mode: 'a')
        end

        def install_deps
          Getch::Bask.new('-a lvm').run!
          Getch::Emerge.new('sys-fs/lvm2 genkernel').pkg!
          exec('systemctl enable lvm2-monitor')
        end

        def exec(cmd)
          Getch::Chroot.new(cmd).run!
        end
      end
    end
  end
end
