module Getch
  module FileSystem
    module Zfs
      class Partition < Getch::FileSystem::Zfs::Device
        def initialize
          super
          @clean = Getch::FileSystem::Clean
          @partition = Getch::FileSystem::Partition.new
          @state = Getch::States.new()
          @log = Getch::Log.new()
          run_partition
        end

        def run_partition
          return if STATES[:partition ]
          @clean.old_zpool
          @clean.struct(@disk, @cache_disk, @home_disk)
          @clean.hdd(@disk, @cache_disk, @home_disk)
          partition
          zfs
          @state.partition
        end

        private

        def partition
          if @efi
            @partition.efi(@dev_esp)
            @partition.swap(@dev_swap)
            @partition.root(@dev_root, "BF00") if @root_part != 1
          else
            @partition.gpt(@dev_gpt)
            # Boot pool for GRUB2
            exec("sgdisk -n2:0:+2G -t2:BE00 #{@dev_boot}") if @dev_boot
            @partition.swap(@dev_swap)
            @partition.root(@dev_root, "BF00") if @root_part != 1
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

          # refresh id
          @id = Helpers::pool_id(@dev_root)

          Helpers::mkdir(MOUNTPOINT)
            
          @log.debug("ashift found for #{@bloc} - #{ashift}")
          if @dev_boot
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
        # /efi      - EFI system partition - 260MB
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
