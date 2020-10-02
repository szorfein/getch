require 'fileutils'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Config < Getch::FileSystem::Ext4::Encrypt::Device
          def initialize
            super
            gen_uuid
            @root_dir = MOUNTPOINT
            @init = '/usr/lib/systemd/systemd'
            move_secret_keys
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
              "options crypt_root=UUID=#{@uuid_root} root=/dev/mapper/root init=#{@init} keymap=#{DEFAULT_OPTIONS[:keyboard]} rw"
            ]
            File.write("#{dir}/gentoo.conf", datas_gentoo.join("\n"))
          end

          def crypttab
            home = @dev_home ? "crypthome UUID=#{@uuid_home} /root/secretkeys/crypto_keyfile.bin luks" : ''
            datas = [
              "cryptswap UUID=#{@uuid_swap} /dev/urandom swap,cipher=aes-xts-plain64:sha256,size=256",
              home
            ]
            File.write("#{@root_dir}/etc/crypttab", datas.join("\n"))
          end

          def grub
            return if Helpers::efi?
            file = "#{@root_dir}/etc/default/grub"
            cmdline = [
              "GRUB_CMDLINE_LINUX=\"resume=#{@dev_swap} crypt_root=UUID=#{@uuid_root} root=/dev/mapper/root init=#{@init} rw slub_debug=P page_poison=1 slab_nomerge pti=on vsyscall=none spectre_v2=on spec_store_bypass_disable=seccomp iommu=force keymap=#{DEFAULT_OPTIONS[:keyboard]}\"",
              "GRUB_ENABLE_CRYPTODISK=y"
            ]
            File.write(file, cmdline.join("\n"), mode: 'a')
          end

          private

          def gen_uuid
            @partuuid_root = `lsblk -o "PARTUUID" #{@dev_root} | tail -1`.chomp() if @dev_root
            @uuid_swap = `lsblk -o "UUID" #{@dev_swap} | tail -1`.chomp() if @dev_swap
            @uuid_root = `lsblk -d -o "UUID" #{@dev_root} | tail -1`.chomp() if @dev_root
            @uuid_boot = `lsblk -o "UUID" #{@dev_boot} | tail -1`.chomp() if @dev_boot
            @uuid_boot_efi = `lsblk -o "UUID" #{@dev_boot_efi} | tail -1`.chomp() if @dev_boot_efi
            @uuid_home = `lsblk -d -o "UUID" #{@dev_home} | tail -1`.chomp() if @dev_home
          end

          def data_fstab
            boot_efi = @dev_boot_efi ? "UUID=#{@uuid_boot_efi} /boot/efi vfat noauto,noatime 1 2" : ''
            swap = @dev_swap ? "#{@luks_swap} none swap discard 0 0 " : ''
            root = @dev_root ? "UUID=#{@uuid_root} / ext4 defaults 0 1" : ''
            home = @dev_home ? "/dev/mapper/crypthome /home/#{@user} ext4 defaults 0 2" : ''

            [ boot_efi, swap, root, home ]
          end

          def move_secret_keys
            return if ! @luks_home
            puts "Moving secret keys"
            keys_path = "#{@root_dir}/root/secretkeys"
            FileUtils.mv("/root/secretkeys", keys_path) if ! Dir.exist?(keys_path)
          end
        end
      end
    end
  end
end
