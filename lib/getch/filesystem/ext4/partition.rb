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
          cleaning
          if Helpers::efi?
            partition_efi
          else
            partition_bios
          end
          @state.partition
        end

        private

        def cleaning
          puts
          print "Cleaning data on #{@disk}, can be long, avoid this on Flash Memory (SSD,USB,...) ? (n,y) "
          case gets.chomp
          when /^y|^Y/
            exec("dd if=/dev/urandom of=/dev/#{@disk} bs=4M status=progress")
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
          exec("sgdisk -n1:1M:+260M -t1:EF00 #{@dev_boot_efi}")
          exec("sgdisk -n2:0:+15G -t2:8304 #{@dev_root}")
          exec("sgdisk -n3:0:+2G -t3:8200 #{@dev_swap}")
          exec("sgdisk -n4:0:0 -t4:8302 #{@dev_home}") if @dev_home
        end

        def partition_bios
          # None      - Bios Boot Partition - 1MiB
          # /         - Root
          # swap      - Linux Swap - size of the ram
          # /home     - Home
          exec("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{@disk}1")
          exec("sgdisk -n2:0:+15G -t2:8304 #{@dev_root}")
          exec("sgdisk -n3:0:+2G -t3:8200 #{@dev_swap}")
          exec("sgdisk -n4:0:0 -t4:8302 #{@dev_home}") if @dev_home
        end

        def exec(cmd)
          Getch::Command.new(cmd).run!
        end
      end
    end
  end
end
