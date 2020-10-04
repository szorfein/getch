module Getch
  module FileSystem
    module Zfs
      class Partition < Getch::FileSystem::Zfs::Device
        def initialize
          super
          @state = Getch::States.new()
          @log = Getch::Log.new()
          run_partition
        end

        def run_partition
          return if STATES[:partition ]
          clear_struct
          cleaning
          partition
          zfs
          @state.partition
        end

        private

        def clear_struct
          oldvg = `vgdisplay | grep #{@vg}`.chomp
          exec("vgremove -f #{@vg}") if oldvg != '' # remove older volume group
          exec("pvremove -f #{@dev_root}") if oldvg != '' and File.exist? @dev_root # remove older volume group

          exec("sgdisk -Z /dev/#{@disk}")
          exec("wipefs -a /dev/#{@disk}")
        end

        def cleaning
          @bloc=`blockdev --getbsz /dev/#{@disk}`.chomp
          puts
          print "Cleaning data on #{@disk}, can be long, avoid this on Flash Memory (SSD,USB,...) ? (n,y) "
          case gets.chomp
          when /^y|^Y/
            exec("dd if=/dev/urandom of=/dev/#{@disk} bs=#{@bloc} status=progress")
          else
            return
          end
        end

        def partition
          mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'
          if Helpers::efi?
            exec("sgdisk -n1:1M:+260M -t1:EF00 /dev/#{@disk}")
            exec("sgdisk -n2:0:+#{mem} -t2:8200 /dev/#{@disk}")
            exec("sgdisk -n3:0:+0 -t3:BF00 /dev/#{@disk}")
          else
            exec("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{@disk}")
            exec("sgdisk -n2:0:+128MiB -t2:8300 /dev/#{@disk}")
            exec("sgdisk -n3:0:+#{mem} -t3:8200 /dev/#{@disk}")
            exec("sgdisk -n4:0:+0 -t4:BF00 /dev/#{@disk}")
          end
        end

        def zfs
          ashift = case @bloc
            when 8096
              13
            when 4096
              12
            else # 512
              9
            end
            
          @log.debug("ashift found for #{@bloc} - #{ashift}")
          exec("zpool create -o ashift=#{ashift} \
            -O atime=off -O acltype=posixacl -O compression=lz4 \
            -O dnodesize=auto -O normalization=formD -O xattr=sa \
            -O devices=off -O setuid=off \
            -R #{MOUNTPOINT} -m none #{@pool_name} \
            #{@dev_root}")
          add_datasets
        end

        def add_datasets
          exec("zfs create #{@pool_name}/gentoo")
          exec("zfs create -o mountpoint=/ #{@pool_name}/gentoo/os")
          exec("zfs create -o mountpoint=/home #{@pool_name}/gentoo/home")
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
