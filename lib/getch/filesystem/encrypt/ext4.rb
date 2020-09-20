module Getch
  module FileSystem
    module Encrypt
      class Ext4 < Getch::FileSystem::Root
        def initialize(disk)
          @disk = disk
          @fs = 'ext4'
          @vg = 'vg0'
          super
        end

        class Mount < Getch::Mount
          def initialize(disk, user)
            @disk = disk
            @user = user
            super
          end

          private

          def gen_vars
            @dev_boot_efi = Helpers::efi? ? "/dev/#{@disk}1" : nil
            @dev_swap = "/dev/mapper/#{@vg}-swap"
            @dev_root = "/dev/mapper/#{@vg}-root"
            @dev_home = @user ? "/dev/mapper/#{@vg}-home" : nil
          end

          def data_fstab
            boot_efi = @dev_boot_efi ? "UUID=#{@uuid_boot_efi} /boot/efi vfat noauto,defaults  0 2" : ''
            swap = @dev_swap ? "UUID=#{@uuid_swap} none swap discard 0 0" : ''
            root = @dev_root ? "UUID=#{@uuid_root} / ext4 defaults 0 1" : ''
            home = @dev_home ? "UUID=#{@uuid_home} /home/#{@user} ext4 defaults 0 2" : ''

            return [ boot_efi, swap, root, home ]
          end
        end

        private

        # Follow https://wiki.archlinux.org/index.php/Partitioning
        def partition_efi
          # /boot/efi - EFI system partition - 260MB
          # LVM vg0   - Root vg0
          # |------>  - /         - 15G
          # |------>  - swap      - Linux Swap - size of the ram
          # |------>  - /home     - Home
          exec("sgdisk -n1:1M:+260M -t1:EF00 /dev/#{@disk}")
          exec("sgdisk -n2:0:0 -t2:8e00 /dev/#{@disk}")
          disk_encrypt
        end

        def format_efi
          exec("mkfs.fat -F32 /dev/#{@disk}1")
          exec("mkfs.#{@fs} /dev/mapper/#{@vg}-root")
          exec("mkswap /dev/mapper/#{@vg}-swap")
          exec("mkfs.#{@fs} /dev/mapper/#{@vg}-home") if @user
        end

        def partition_bios
          # None      - Bios Boot Partition - 1MiB
          # LVM vg0   - Root vg0
          # |------>  - /         - 15G
          # |------>  - swap      - Linux Swap - size of the ram
          # |------>  - /home     - Home
          exec("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{@disk}")
          exec("sgdisk -n2:0:0 -t2:8e00 /dev/#{@disk}")
          disk_encrypt_bios
        end

        def format_bios
          exec("mkfs.#{@fs} /dev/mapper/#{@vg}-root")
          exec("mkswap /dev/mapper/#{@vg}-swap")
          exec("mkfs.#{@fs} /dev/mapper/#{@vg}-home") if @user
        end

        def disk_encrypt
          exec("cryptsetup luksFormat -c aes-xts-plain64:sha256 -s 256 /dev/#{@disk}2")
          exec("cryptsetup open --type luks /dev/#{@disk}2 crypt-lvm")
          lvm_setup
        end

        def lvm_setup
          exec("pvcreate /dev/mapper/crypt-lvm")
          exec("vgcreate #{@vg} /dev/mapper/crypt-lvm")
          exec("lvcreate -L 15G -n root #{@vg}")
          exec("lvcreate -L 2G -n swap #{@vg}")
          exec("lvcreate -l 100%FREE -n home #{@vg}") if @user
          exec("vgchange --available y")
        end

        def exec(cmd)
          Getch::Command.new(cmd).run!
        end
      end
    end
  end
end
