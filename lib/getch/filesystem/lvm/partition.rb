module Getch
  module FileSystem
    module Lvm
      class Partition < Getch::FileSystem::Lvm::Device
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
          lvm
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

        def boot
          if Helpers::efi?
            exec("sgdisk -n1:1M:+260M -t1:EF00 /dev/#{@disk}}")
          else
            exec("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{@disk}")
          end
        end

        def others
          exec("sgdisk -n2:0:+0 -t2:8309 /dev/#{@disk}")
        end

        def lvm
          mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'
          exec("pvcreate /dev/#{@disk}2")
          exec("vgcreate #{@vg} /dev/#{@disk}2")
          exec("lvcreate -L 15G -n root #{@vg}")
          exec("lvcreate -L #{mem} -n swap #{@vg}")
          exec("lvcreate -l 100%FREE -n home #{@vg}") if @user
          exec("vgchange --available y")
        end

        # Follow https://wiki.archlinux.org/index.php/Partitioning
        # Partition_efi
        # /boot/efi - EFI system partition - 260MB
        # /         - Root

        # Partition_bios
        # None      - Bios Boot Partition - 1MiB
        # /         - Root

        def exec(cmd)
          Getch::Command.new(cmd).run!
        end
      end
    end
  end
end
