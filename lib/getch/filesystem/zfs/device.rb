module Getch
  module FileSystem
    module Zfs
      class Device
        def initialize
          @disk = DEFAULT_OPTIONS[:disk]
          @user = DEFAULT_OPTIONS[:username]
          @dev_boot_efi = Helpers::efi? ? "/dev/#{@disk}1" : nil
          @dev_boot = Helpers::efi? ? nil : "/dev/#{@disk}2"
          @dev_swap = Helpers::efi? ? "/dev/#{@disk}2" : "/dev/#{@disk}3"
          @dev_root = Helpers::efi? ? "/dev/#{@disk}3" : "/dev/#{@disk}4"
          @boot_pool_name = 'bpool'
          @pool_name = 'zpool'
          @zfs_home = @user ? true : false
        end
      end
    end
  end
end
