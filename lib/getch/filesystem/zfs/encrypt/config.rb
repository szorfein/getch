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
              "options crypt_root=UUID=#{@uuid_dev_root} root=#{@lv_root} init=#{@init} keymap=#{DEFAULT_OPTIONS[:keymap]} dolvm rw"
            ]
            File.write("#{dir}/gentoo.conf", datas_gentoo.join("\n"))
          end

          def crypttab
            datas = [
              "cryptswap #{@lv_swap} /dev/urandom swap,cipher=aes-xts-plain64:sha256,size=256"
            ]
            File.write("#{@root_dir}/etc/crypttab", datas.join("\n"))
          end

          def grub
            return if Helpers::efi?
            file = "#{@root_dir}/etc/default/grub"
            cmdline = [ 
              "GRUB_CMDLINE_LINUX=\"crypt_root=UUID=#{@uuid_dev_root} root=#{@lv_root} init=#{@init} dolvm rw slub_debug=P page_poison=1 slab_nomerge pti=on vsyscall=none spectre_v2=on spec_store_bypass_disable=seccomp iommu=force keymap=#{DEFAULT_OPTIONS[:keymap]}\"",
              "GRUB_ENABLE_CRYPTODISK=y"
            ]
            File.write("#{file}", cmdline.join("\n"), mode: 'a')
          end

          private

          def gen_uuid
            @uuid_swap = `lsblk -o "UUID" #{@lv_swap} | tail -1`.chomp() if @lv_swap
            @uuid_root = `lsblk -d -o "UUID" #{@lv_root} | tail -1`.chomp() if @lv_root
            @uuid_dev_root = `lsblk -d -o "UUID" #{@dev_root} | tail -1`.chomp() if @dev_root
            @uuid_boot = `lsblk -o "UUID" #{@dev_boot} | tail -1`.chomp() if @dev_boot
            @uuid_boot_efi = `lsblk -o "UUID" #{@dev_boot_efi} | tail -1`.chomp() if @dev_boot_efi
            @uuid_home = `lsblk -o "UUID" #{@lv_home} | tail -1`.chomp() if @lv_home
          end

          def data_fstab
            boot_efi = @dev_boot_efi ? "UUID=#{@uuid_boot_efi} /boot/efi vfat noauto,noatime 1 2" : ''
            boot = @dev_boot ? "UUID=#{@uuid_boot} /boot ext4 noauto,noatime 1 2" : ''
            swap = @lv_swap ? "/dev/mapper/cryptswap none swap discard 0 0" : ''
            root = @lv_root ? "UUID=#{@uuid_root} / ext4 defaults 0 1" : ''
            home = @lv_home ? "UUID=#{@uuid_home} /home/#{@user} ext4 defaults 0 2" : ''

            [ boot_efi, boot, swap, root, home ]
          end
        end
      end
    end
  end
end
