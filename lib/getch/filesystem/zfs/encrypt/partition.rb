module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Partition < Getch::FileSystem::Zfs::Encrypt::Device
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
            oldzpool = `zpool status | grep pool:`.gsub(/pool: /, '').delete(' ').split("\n")
            if oldzpool[0] != "" and $?.success?
              oldzpool.each { |p| exec("zpool destroy #{p}") if p }
            end
            exec("vgremove -f #{@vg}") if oldvg != '' # remove older volume group
            exec("pvremove -f #{@dev_root}") if oldvg != '' and File.exist? @dev_root # remove older volume group

            exec("sgdisk -Z /dev/#{@disk}")
            exec("wipefs -a /dev/#{@disk}")
          end

          # See https://wiki.archlinux.org/index.php/Solid_state_drive/Memory_cell_clearing
          # for SSD
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
              exec("sgdisk -n2:0:+2G -t2:BE00 /dev/#{@disk}") # boot pool GRUB
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

            Helpers::mkdir(MOUNTPOINT)

            @log.debug("ashift found for #{@bloc} - #{ashift}")
            if ! Helpers::efi? 
              # https://openzfs.github.io/openzfs-docs/Getting%20Started/Ubuntu/Ubuntu%2020.04%20Root%20on%20ZFS.html
              @log.info("Creating boot pool on #{@pool_name}")
              exec("zpool create -f \\
              -o ashift=#{ashift} -d \\
              -o feature@async_destroy=enabled \\
              -o feature@bookmarks=enabled \\
              -o feature@embedded_data=enabled \\
              -o feature@empty_bpobj=enabled \\
              -o feature@enabled_txg=enabled \\
              -o feature@extensible_dataset=enabled \\
              -o feature@filesystem_limits=enabled \\
              -o feature@hole_birth=enabled \\
              -o feature@large_blocks=enabled \\
              -o feature@lz4_compress=enabled \\
              -o feature@spacemap_histogram=enabled \\
              -O acltype=posixacl -O canmount=off -O compression=lz4 \\
              -O devices=off -O normalization=formD -O atime=off -O xattr=sa \\
              -O mountpoint=/boot -R #{MOUNTPOINT} \\
              #{@boot_pool_name} #{@dev_boot}
                   ")
            end

            exec("zpool create -f -o ashift=#{ashift} \\
            -O acltype=posixacl -O canmount=off -O compression=lz4 \\
            -O dnodesize=auto -O normalization=formD -O atime=off \\
            -O xattr=sa -O mountpoint=/ -R #{MOUNTPOINT} \\
            #{@pool_name} #{@dev_root}
                 ")

            add_datasets
          end

          def add_datasets
            exec("zfs create -o canmount=off -o mountpoint=none #{@pool_name}/ROOT")
            exec("zfs create -o canmount=off -o mountpoint=none #{@boot_pool_name}/BOOT") if @dev_boot

            exec("zfs create -o canmount=noauto -o mountpoint=/ #{@pool_name}/ROOT/gentoo")
            # set bootfs
            #exec("zpool set bootfs=#{@pool_name}/ROOT/gentoo #{@pool_name}")
            exec("zfs create -o canmount=noauto -o mountpoint=/boot #{@boot_pool_name}/BOOT/gentoo") if @dev_boot

            exec("zfs create -o canmount=off #{@pool_name}/ROOT/gentoo/usr")
            exec("zfs create #{@pool_name}/ROOT/gentoo/usr/src")
            exec("zfs create -o canmount=off #{@pool_name}/ROOT/gentoo/var")
            exec("zfs create #{@pool_name}/ROOT/gentoo/var/log")
            exec("zfs create #{@pool_name}/ROOT/gentoo/var/db")
            exec("zfs create #{@pool_name}/ROOT/gentoo/var/tmp")

            exec("zfs create -o canmount=off -o mountpoint=/ #{@pool_name}/USERDATA")
            exec("zfs create -o canmount=on -o mountpoint=/root #{@pool_name}/USERDATA/root")
            exec("zfs create -o canmount=on -o mountpoint=/home/#{@user} #{@pool_name}/USERDATA/#{@user}") if @user
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
end
