require 'fileutils'

module Getch
  module FileSystem
    module Zfs
      class Mount < Getch::FileSystem::Zfs::Device
        def initialize
          super
          @root_dir = MOUNTPOINT
          @mount = Getch::FileSystem::Mount.new
          @state = Getch::States.new
          @log = Getch::Log.new
        end

        def run
          return if STATES[:mount]
          exec("zpool export -a")
          exec("rm -rf #{MOUNTPOINT}/*")
          exec("zpool import -N -R #{MOUNTPOINT} #{@pool_name}")
          exec("zpool import -N -R #{MOUNTPOINT} #{@boot_pool_name}") if @dev_boot
          @mount.swap(@dev_swap)
          mount_root
          mount_boot
          @mount.esp(@dev_esp)
          exec("zfs mount -a")
          @state.mount
        end

        private

        def mount_root
          Helpers::mkdir(@root_dir)
          exec("zfs mount #{@pool_name}/ROOT/gentoo")
        end

        def mount_boot
          return if ! @dev_boot
          exec("zfs mount #{@boot_pool_name}/BOOT/gentoo")
        end

        def exec(cmd)
          @log.info("==> #{cmd}")
          Helpers::sys(cmd)
        end
      end
    end
  end
end
