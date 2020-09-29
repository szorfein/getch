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
          partition
          lvm
          @state.partition
        end

        private

        def clear_struct
          oldvg = `vgdisplay | grep #{@vg}`.chomp
          exec("vgremove -f #{@vg}") if oldvg # remove older volume group
          exec("pvremove -f #{@dev_root}") if oldvg # remove older volume group

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

        def partition
          if Helpers::efi?
            exec("sgdisk -n1:1M:+260M -t1:EF00 /dev/#{@disk}")
            exec("sgdisk -n2:0:+0 -t2:8e00 /dev/#{@disk}")
          else
            exec("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{@disk}")
            exec("sgdisk -n2:0:+128MiB -t1:8300 /dev/#{@disk}")
            exec("sgdisk -n3:0:+0 -t2:8e00 /dev/#{@disk}")
          end
        end

        def lvm
          mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'
          exec("pvcreate -f #{@dev_root}")
          exec("vgcreate -f #{@vg} #{@dev_root}")
          exec("lvcreate -W y -L 15G -n root #{@vg}")
          exec("lvcreate -W y -L #{mem} -n swap #{@vg}")
          exec("lvcreate -W y -l 100%FREE -n home #{@vg}") if @user
          exec("vgchange --available y")
        end

        # Follow https://wiki.archlinux.org/index.php/Partitioning
        # Partition_efi
        # /boot/efi - EFI system partition - 260MB
        # /         - Root

        # Partition_bios
        # None      - Bios Boot Partition - 1MiB
        # /boot     - Boot - 8300
        # /         - Root

        def exec(cmd)
          Getch::Command.new(cmd).run!
        end
      end
    end
  end
end
