module Getch
  module FileSystem
    class Ext4 < Getch::FileSystem::Root
      def initialize(disk)
        @disk = disk
        @fs = 'ext4'
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
          @dev_swap = "/dev/#{@disk}2"
          @dev_root = "/dev/#{@disk}3"
          @dev_home = @user ? "/dev/#{@disk}4" : nil
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
        # swap      - Linux Swap - size of the ram
        # /         - Root
        # /home     - Home
        system("sgdisk -n1:1M:+260M -t1:EF00 /dev/#{@disk}") # boot EFI
        system("sgdisk -n2:0:+2G -t2:8200 /dev/#{@disk}") # swap
        system("sgdisk -n3:0:+15G -t3:8304 /dev/#{@disk}") # root
        system("sgdisk -n4:0:0 -t3:8302 /dev/#{@disk}") # home
      end

      def format_efi
        system("mkfs.fat -F32 /dev/#{@disk}1")
        system("mkswap /dev/#{@disk}2")
        system("mkfs.#{@fs} /dev/#{@disk}3")
        system("mkfs.#{@fs} /dev/#{@disk}4")
      end

      def partition_bios
        # None      - Bios Boot Partition - 1MiB
        # swap      - Linux Swap - size of the ram
        # /         - Root
        # /home     - Home
        system("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{@disk}")
        system("sgdisk -n2:0:+2G -t2:8200 /dev/#{@disk}")
        system("sgdisk -n3:0:+15G -t3:8304 /dev/#{@disk}")
        system("sgdisk -n4:0:0 -t3:8302 /dev/#{@disk}")
      end

      def format_bios
        system("mkswap /dev/#{@disk}2")
        system("mkfs.#{@fs} /dev/#{@disk}3")
        system("mkfs.#{@fs} /dev/#{@disk}4")
      end
    end
  end
end
