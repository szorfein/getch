module Getch
  module FileSystem
    module Ext4
      class Partition < Getch::FileSystem::Ext4::Device
        def initialize
          super
          @state = Getch::States.new()
          run_partition
        end

        def run_partition
          return if STATES[:partition ]
          clear_struct
          cleaning
          if Helpers::efi?
            partition_efi
          else
            partition_bios
          end
          @state.partition
        end

        private

        def clear_struct
          exec("sgdisk -Z /dev/#{@disk}")
          exec("wipefs -a /dev/#{@disk}")
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

        # Follow https://wiki.archlinux.org/index.php/Partitioning
        def partition_efi
          # /boot/efi - EFI system partition - 260MB
          # /         - Root
          # swap      - Linux Swap - size of the ram
          # /home     - Home
          mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'

          exec("sgdisk -n1:1M:+260M -t1:EF00 /dev/#{@disk}")
          exec("sgdisk -n2:0:+#{mem} -t2:8200 /dev/#{@disk}")

          if @dev_home
            exec("sgdisk -n3:0:+18G -t3:8304 /dev/#{@disk}")
            exec("sgdisk -n4:0:0 -t4:8302 /dev/#{@disk}")
          else
            exec("sgdisk -n3:0:0 -t3:8304 /dev/#{@disk}")
          end
        end

        def partition_bios
          # None      - Bios Boot Partition - 1MiB
          # /         - Root
          # swap      - Linux Swap - size of the ram
          # /home     - Home
          mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'

          exec("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{@disk}")
          exec("sgdisk -n2:0:+#{mem} -t2:8200 /dev/#{@disk}")

          if @dev_home
            exec("sgdisk -n3:0:+18G -t3:8304 /dev/#{@disk}")
            exec("sgdisk -n4:0:0 -t4:8302 /dev/#{@disk}")
          else
            exec("sgdisk -n3:0:0 -t3:8304 /dev/#{@disk}")
          end
        end

        def exec(cmd)
          Getch::Command.new(cmd).run!
        end
      end
    end
  end
end
