# frozen_string_literal: true

module Getch
  module FileSystem
    module Lvm
      module Encrypt
        class Config < Getch::FileSystem::Lvm::Encrypt::Device
          def initialize
            super
            gen_uuid
            @init = '/usr/lib/systemd/systemd'
            crypttab
          end

          def fstab
            file = "#{MOUNTPOINT}/etc/fstab"
            datas = data_fstab
            File.write file, datas.join("\n")
          end

          def systemd_boot
            return unless Helpers.efi?

            esp = '/efi'
            dir = "#{MOUNTPOINT}/#{esp}/loader/entries/"
            datas_gentoo = [
              'title Gentoo Linux',
              'linux /vmlinuz',
              'initrd /initramfs',
              "options crypt_root=UUID=#{@uuid_dev_root} root=/dev/mapper/root real_root=#{@lv_root} init=#{@init} keymap=#{Getch::OPTIONS[:keymap]} dolvm rw"
            ]
            File.write("#{dir}/gentoo.conf", datas_gentoo.join("\n"))
          end

          def crypttab
            datas = [
              "cryptswap #{@lv_swap} /dev/urandom swap,cipher=aes-xts-plain64:sha256,size=512"
            ]
            File.write("#{MOUNTPOINT}/etc/crypttab", datas.join("\n"))
          end

          def grub
            return if Helpers.efi?

            file = "#{MOUNTPOINT}/etc/default/grub"
            cmdline = [ 
              "GRUB_CMDLINE_LINUX=\"crypt_root=UUID=#{@uuid_dev_root} root=/dev/mapper/root real_root=#{@lv_root} init=#{@init} dolvm rw slub_debug=P page_poison=1 slab_nomerge pti=on vsyscall=none spectre_v2=on spec_store_bypass_disable=seccomp iommu=force keymap=#{Getch::OPTIONS[:keymap]}\"",
              "GRUB_ENABLE_CRYPTODISK=y"
            ]
            File.write(file, cmdline.join("\n"), mode: 'a')
          end

          private

          def gen_uuid
            @uuid_dev_root = `lsblk -d -o "UUID" #{@dev_root} | tail -1`.chomp() if @dev_root
            @uuid_boot = `lsblk -o "UUID" #{@dev_boot} | tail -1`.chomp() if @dev_boot
            @uuid_esp = `lsblk -o "UUID" #{@dev_esp} | tail -1`.chomp() if @dev_esp
          end

          def data_fstab
            boot_efi = @dev_esp ? "UUID=#{@uuid_esp} /efi vfat noauto,noatime 1 2" : ''
            boot = @dev_boot ? "UUID=#{@uuid_boot} /boot ext4 noauto,noatime 1 2" : ''
            swap = "/dev/mapper/cryptswap none swap discard 0 0"
            root = "#{@lv_root} / ext4 defaults 0 1"
            home = @lv_home ? "#{@lv_home} /home/#{@user} ext4 defaults 0 2" : ''

            [ boot_efi, boot, swap, root, home ]
          end
        end
      end
    end
  end
end
