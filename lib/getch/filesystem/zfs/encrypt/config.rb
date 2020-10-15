module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Config < Getch::FileSystem::Zfs::Encrypt::Device
          def initialize
            super
            gen_uuid
            @root_dir = MOUNTPOINT
            @init = '/usr/lib/systemd/systemd'
            crypttab
          end

          def fstab
            file = "#{@root_dir}/etc/fstab"
            datas = data_fstab
            File.write(file, datas.join("\n"))
          end

          def systemd_boot
            return if ! Helpers::efi? 
            esp = '/boot/efi'
            dir = "#{@root_dir}/#{esp}/loader/entries/"
            datas_gentoo = [
              'title Gentoo Linux',
              'linux /vmlinuz',
              'initrd /initramfs',
              "options root=ZFS=#{@pool_name}/ROOT/gentoo init=#{@init} dozfs keymap=#{DEFAULT_OPTIONS[:keymap]}"
            ]
            File.write("#{dir}/gentoo.conf", datas_gentoo.join("\n"))
          end

          def crypttab
            datas = [
              "cryptswap UUID=#{@uuid_swap} /dev/urandom swap,cipher=aes-xts-plain64:sha256,size=256"
            ]
            File.write("#{@root_dir}/etc/crypttab", datas.join("\n"))
          end

          # See https://wiki.gentoo.org/wiki/ZFS#ZFS_root
          def grub
            return if Helpers::efi?
            file = "#{@root_dir}/etc/default/grub"
            cmdline = [ 
              "GRUB_CMDLINE_LINUX=\"root=ZFS=#{@pool_name}/ROOT/gentoo init=#{@init} dozfs keymap=#{DEFAULT_OPTIONS[:keymap]}\""
            ]
            File.write("#{file}", cmdline.join("\n"), mode: 'a')
          end

          private

          def gen_uuid
            @uuid_swap = `lsblk -o "UUID" #{@dev_swap} | tail -1`.chomp()
            @uuid_boot_efi = `lsblk -o "UUID" #{@dev_boot_efi} | tail -1`.chomp() if @dev_boot_efi
          end

          def data_fstab
            boot_efi = @dev_boot_efi ? "UUID=#{@uuid_boot_efi} /boot/efi vfat noauto,noatime 1 2" : ''
            swap = @dev_swap ? "/dev/mapper/cryptswap none swap discard 0 0" : ''

            [ boot_efi, swap ]
          end
        end
      end
    end
  end
end
