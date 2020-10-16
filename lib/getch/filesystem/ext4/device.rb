module Getch
  module FileSystem
    module Ext4
      class Device
        def initialize
          @disk = DEFAULT_OPTIONS[:disk]
          @user = DEFAULT_OPTIONS[:username]
          @dev_boot_efi = Helpers::efi? ? "/dev/#{@disk}1" : nil
          @dev_swap = "/dev/#{@disk}2"
          @dev_root = "/dev/#{@disk}3"
          @dev_home = @user ? "/dev/#{@disk}4" : nil
        end
      end
    end
  end
end
