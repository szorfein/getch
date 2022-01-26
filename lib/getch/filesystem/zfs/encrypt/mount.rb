# frozen_string_literal: true

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Mount < Device
          def initialize
            super
            @mount = Getch::FileSystem::Mount.new
            @state = Getch::States.new
            @log = Getch::Log.new
            @import = '/dev/disk/by-id'
          end

          def run
            return if STATES[:mount]

            exec('zpool export -a')
            exec("rm -rf #{MOUNTPOINT}/*")
            exec("zpool import -N -d #{@import} -R #{MOUNTPOINT} #{@pool_name}")
            exec("zpool import -f -N -d #{@import} -R #{MOUNTPOINT} #{@boot_pool_name}") if @dev_boot
            exec('zfs load-key -a')
            mount_root
            mount_boot
            @mount.esp(@dev_esp)
            exec('zfs mount -a')
            @state.mount
          end

          private

          def mount_root
            Helpers.mkdir(MOUNTPOINT)
            exec("zfs mount #{@pool_name}/ROOT/#{@n}")
          end

          def mount_boot
            return unless @dev_boot

            exec("zfs mount #{@boot_pool_name}/BOOT/#{@n}")
          end

          def exec(cmd)
            @log.info("==> #{cmd}")
            Helpers.sys(cmd)
          end
        end
      end
    end
  end
end
