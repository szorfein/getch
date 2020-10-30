module Getch
  module FileSystem
    module Zfs
      class Format < Getch::FileSystem::Zfs::Device
        def initialize
          super
          @log = Getch::Log.new
          @state = Getch::States.new
          if ! @id
            @log.info "Research pool id for #{@dev_root}..."
            sleep 2 until Helpers::pool_id(@dev_root)
            @id = Helpers::pool_id(@dev_root)
            @boot_pool_name = "bpool-#{@id}"
            @pool_name = "rpool-#{@id}"
          end
          format
        end

        private

        def format
          return if STATES[:format]
          raise "Error, no id found for #{@dev_root}." if ! @id
          @log.info "Create #{@id} for #{@pool_name}"
          system("mkfs.fat -F32 #{@dev_esp}") if @dev_esp
          system("mkswap -f #{@dev_swap}")
          zfs
          datasets
          @state.format
        end

        def zfs
          bloc=`blockdev --getbsz #{@dev_root}`.chomp
          ashift = case bloc
            when 8096
              13
            when 4096
              12
            else # 512
              9
            end

          Helpers::mkdir(MOUNTPOINT)
          @log.debug("ashift found for #{bloc} - #{ashift}")

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
        end

        def datasets
          exec("zfs create -o canmount=off -o mountpoint=none #{@pool_name}/ROOT")
          exec("zfs create -o canmount=off -o mountpoint=none #{@boot_pool_name}/BOOT") if @dev_boot

          exec("zfs create -o canmount=noauto -o mountpoint=/ #{@pool_name}/ROOT/gentoo")
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

        def exec(cmd)
          Getch::Command.new(cmd).run!
        end
      end
    end
  end
end
