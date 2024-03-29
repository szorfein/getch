# frozen_string_literal: true

require 'mountfs'

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Mount
          def initialize
            x
          end

          private

          def x
            MountFs::Zfs.new(DEVS, OPTIONS)

            #exec('zpool export -a')
            #exec("rm -rf #{MOUNTPOINT}/*")
            #exec("zpool import -N -d #{@import} -R #{MOUNTPOINT} #{@pool_name}")
            #exec("zpool import -f -N -d #{@import} -R #{MOUNTPOINT} #{@boot_pool_name}") if @dev_boot
            #exec('zfs load-key -a')
            #mount_root
            #mount_boot
            #@mount.esp(@dev_esp)
            #exec('zfs mount -a')
          end
        end
      end
    end
  end
end
