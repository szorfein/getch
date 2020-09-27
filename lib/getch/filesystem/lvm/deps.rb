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

        private
        def install_efi
        end

        def install_bios
          exec("euse -p sys-boot/grub -E device-mapper")
        end

        def install_deps
          exec("euse -E lvm")
          Getch::Emerge.new('genkernel lvm2').pkg!
          exec("genkernel --install --lvm --kernel-config=/usr/src/linux/.config initramfs")
          exec("systemctl enable lvm2-monitor")
        end

        def exec(cmd)
          Helpers::run_chroot(cmd, MOUNTPOINT)
        end
      end
    end
  end
end
