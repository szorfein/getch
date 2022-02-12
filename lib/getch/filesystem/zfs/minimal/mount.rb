# frozen_string_literal: true

require 'mountfs'

module Getch
  module FileSystem
    module Zfs
      module Minimal
        class Mount
          def initialize
            x
          end

          def x
            MountFs::Zfs.new(DEVS, OPTIONS)
            #exec("zpool import -N -d #{@import} -R #{MOUNTPOINT} #{@pool_name}")
            #exec("zpool import -f -N -d #{@import} -R #{MOUNTPOINT} #{@boot_pool_name}") if @dev_boot
          end
        end
      end
    end
  end
end
