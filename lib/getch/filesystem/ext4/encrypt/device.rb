module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Device < Getch::FileSystem::Device
          def initialize
            super
            @luks_root = '/dev/mapper/cryptroot'
            @luks_home = @home_disk ? '/dev/mapper/crypthome' : nil
            @luks_swap = '/dev/mapper/cryptswap'
          end
        end
      end
    end
  end
end
