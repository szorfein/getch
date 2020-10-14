require 'fileutils'

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Mount < Getch::FileSystem::Zfs::Encrypt::Device
          def initialize
            super
            @root_dir = MOUNTPOINT
            @boot_dir = "#{@root_dir}/boot"
            @boot_efi_dir = "#{@root_dir}/boot/efi"
            @state = Getch::States.new()
            @log = Getch::Log.new
          end

          def run
            return if STATES[:mount]
            exec("zpool export -a")
            exec("rm -rf #{MOUNTPOINT}/*")
            exec("zpool import -N -R #{MOUNTPOINT} #{@pool_name}")
            exec("zpool import -N -R #{MOUNTPOINT} #{@boot_pool_name}") if @dev_boot
            mount_swap
            mount_root
            mount_boot
            mount_boot_efi
            exec("zfs mount -a")
            @state.mount
          end

          private

          def mount_swap
            if Helpers::grep?('/proc/swaps', /^\/dev/)
              exec("swapoff #{@dev_swap}")
            end

            exec("swapon #{@dev_swap}")
          end

          def mount_root
            Helpers::mkdir(@root_dir)
            exec("zfs mount #{@pool_name}/ROOT/gentoo")
          end

          def mount_boot_efi
            return if ! @dev_boot_efi
            Helpers::mkdir(@boot_efi_dir)
            exec("mount #{@dev_boot_efi} #{@boot_efi_dir}")
          end

          def mount_boot
            return if ! @dev_boot
            Helpers::mkdir(@boot_dir)
            exec("zfs mount #{@boot_pool_name}/BOOT/gentoo")
          end

          def exec(cmd)
            @log.info("==> #{cmd}")
            system(cmd)
            unless $?.success?
              raise "Error with #{cmd}"
            end
          end
        end
      end
    end
  end
end
