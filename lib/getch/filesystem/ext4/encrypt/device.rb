module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Device
          def initialize
            @disk = DEFAULT_OPTIONS[:disk]
            @user = DEFAULT_OPTIONS[:username]
            @dev_boot_efi = Helpers::efi? ? "/dev/#{@disk}1" : nil
            @dev_root = "/dev/#{@disk}2"
            @dev_swap = "/dev/#{@disk}3"
            @dev_home = @user ? "/dev/#{@disk}4" : nil
            @luks_root = "/dev/mapper/cryptroot"
            @luks_home = @user ? "/dev/mapper/crypthome" : nil
            @luks_swap = "/dev/mapper/cryptswap"
          end
        end
      end
    end
  end
end
