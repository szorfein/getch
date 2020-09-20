module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Partition < Getch::FileSystem::Ext4::Encrypt::Device
          def initialize
            super
            @state = Getch::States.new()
            run_partition
          end

          def run_partition
            return if STATES[:partition ]
            clear_struct
            cleaning
            boot
            others
            luks
            lvm
            @state.partition
          end

          private

          def clear_struct
            exec("sgdisk -Z #{@disk}")
            exec("wipefs -a #{@disk}")
          end

          def cleaning
            puts
            print "Cleaning data on #{@disk}, can be long, avoid this on Flash Memory (SSD,USB,...) ? (n,y) "
            case gets.chomp
            when /^y|^Y/
              bloc=`blockdev --getbsz /dev/#{@disk}`.chomp
              exec("dd if=/dev/urandom of=/dev/#{@disk} bs=#{bloc} status=progress")
            else
              return
            end
          end

          def boot
            if Helpers::efi?
              exec("sgdisk -n1:1M:+260M -t1:EF00 #{@dev_boot_efi}")
            else
              exec("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{@disk}1")
            end
          end

          def others
            exec("sgdisk -n2:0:+0 -t2:8309 #{@dev_root}")
          end

          def luks
            if Helpers::efi?
              exec("cryptsetup --use-random luksFormat /dev/#{@disk}2")
              exec("cryptsetup open --type luks /dev/#{@disk}2 crypt-lvm")
            else
              # GRUB do not support LUKS2
              exec("cryptsetup --use-random luksFormat --type luks1 /dev/#{@disk}2")
              exec("cryptsetup open --type luks1 /dev/#{@disk}2 crypt-lvm")
            end
          end

          def lvm
            mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'
            exec("pvcreate /dev/mapper/crypt-lvm")
            exec("vgcreate #{@vg} /dev/mapper/crypt-lvm")
            exec("lvcreate -L 15G -n root #{@vg}")
            exec("lvcreate -L #{mem} -n swap #{@vg}")
            exec("lvcreate -l 100%FREE -n home #{@vg}") if @user
            exec("vgchange --available y")
          end

          # Follow https://wiki.archlinux.org/index.php/Partitioning
          # Partition_efi
            # /boot/efi - EFI system partition - 260MB
            # /         - Root
            # swap      - Linux Swap - size of the ram
            # /home     - Home

          # Partition_bios
            # None      - Bios Boot Partition - 1MiB
            # /         - Root
            # swap      - Linux Swap - size of the ram
            # /home     - Home

          def exec(cmd)
            Getch::Command.new(cmd).run!
          end
        end
      end
    end
  end
end
