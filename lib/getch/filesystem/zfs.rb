module Getch
  module FileSystem
    module Zfs
    end
  end
end

require_relative 'zfs/device'
require_relative 'zfs/partition'
require_relative 'zfs/format'
require_relative 'zfs/mount'
require_relative 'zfs/config'
require_relative 'zfs/deps'
require_relative 'zfs/encrypt'
